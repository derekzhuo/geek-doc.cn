#!/bin/bash
# day-04 实验 4.1b：线程数扩展扫描（v2）
# 修复点：
#   1. pkill -9 强杀（服务端 SIGTERM 只置 running 标志，epoll_wait(-1) 会卡死退出流程）
#   2. 启动后校验监听 socket 数 == 线程数，防止旧进程残留叠加（SO_REUSEPORT 会共享端口）
#   3. warmup 一轮丢弃首轮（首轮可能因服务端刚就绪输出为空）
cd /root/echo-day04 || exit 1
rm -rf results41c && mkdir -p results41c

clean() {
  pkill -9 -x echo-mt-server 2>/dev/null
  sleep 2
  # 等端口真正释放（最多 10 秒）
  for _ in $(seq 1 10); do
    local nn
    nn=$(ss -tln | grep -c 9988)
    [ "$nn" = "0" ] && break
    sleep 1
  done
}

for n in 1 2 4 8; do
  clean
  nohup ./echo-mt-server 9988 "$n" lt > /tmp/mt-"$n".log 2>&1 &
  sleep 3
  cnt=$(ss -tln | grep -c 9988)
  echo "[t$n] listening sockets=$cnt (expect $n)"
  [ "$cnt" -lt "$n" ] && { echo "WARN: expect $n listeners, got $cnt"; continue; }

  # warmup 一轮（丢弃）
  timeout 30 ./echo-kp-bench 127.0.0.1 9988 100 10 --mode long > /dev/null 2>&1

  for c in 100 1000; do
    for i in 1 2 3 4 5; do
      timeout 30 ./echo-kp-bench 127.0.0.1 9988 "$c" 10 --mode long \
        > results41c/t${n}-c${c}-r$i.txt 2>&1
      s=$(stat -c%s results41c/t${n}-c${c}-r$i.txt 2>/dev/null || echo 0)
      echo "  t${n}-c${c}-r$i size=$s"
    done
  done
done

clean
echo "=== 41c DONE ==="
