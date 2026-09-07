#!/bin/bash
# day-04 实验 4.4：单线程 vs 多线程 CPU 利用率对比
# 压测期间用 pidstat 采样服务端 CPU%，mpstat 采样整机各核
cd /root/echo-day04 || exit 1
rm -rf results44 && mkdir -p results44

clean() {
  pkill -9 -x echo-mt-server 2>/dev/null
  sleep 2
  for _ in $(seq 1 10); do
    local nn
    nn=$(ss -tln | grep -c 9988)
    [ "$nn" = "0" ] && break
    sleep 1
  done
}

for n in 1 2 4; do
  clean
  nohup ./echo-mt-server 9988 "$n" lt > /tmp/mt44.log 2>&1 &
  sleep 3
  pid=$(pgrep -x echo-mt-server | head -1)
  echo "[t$n] pid=$pid threads=$n"
  # 压测轮数按线程数放大，保证压测时长稳定在 ~20 秒（此前 t1 1000 轮跑 16s，
  # 而 t2/t4 同样 1000 轮只跑 ~7s，导致 8 秒采样窗口只采到压测尾部，数据无效）
  case $n in
    1) rounds=1250 ;;  # QPS ~6.3万 → ~20s
    2) rounds=2900 ;;  # QPS ~14.5万 → ~20s
    4) rounds=3000 ;;  # QPS ~15万 → ~20s
  esac
  ( timeout 180 ./echo-kp-bench 127.0.0.1 9988 1000 "$rounds" --mode long \
      > results44/bench-t$n.txt 2>&1 & )
  sleep 3
  # 服务端进程 CPU%（含所有线程）采样 8 次 × 1 秒
  pidstat -p "$pid" 1 8 > results44/cpu-t$n.txt 2>&1
  # 整机各核利用率采样 8 次 × 1 秒
  mpstat -P ALL 1 8 > results44/mpstat-t$n.txt 2>&1
  # 等待压测真正结束（最多 60 秒）：kp-bench 在 ( ... & ) 子 shell 中 wait 等不到，
  # 只能轮询进程是否消失。此前缺失此步，t2/t4 压测未跑完就被下一轮 clean 强杀，
  # 导致 bench 文件不完整。
  for _ in $(seq 1 60); do
    pgrep -f "echo-kp-bench" >/dev/null || break
    sleep 1
  done
  echo "--- cpu-t$n (avg) ---"
  tail -6 results44/cpu-t$n.txt | head -5
  echo "--- mpstat-t$n avg rows ---"
  grep -E "Average" results44/mpstat-t$n.txt
done

clean
echo "=== 44 DONE ==="
