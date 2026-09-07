#!/bin/bash
# day-04 实验 4.2（LT vs ET @4线程）+ 4.3（连接数扫描 @4线程 LT）
cd /root/echo-day04 || exit 1
rm -rf results42 results43 && mkdir -p results42 results43

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

# ===== 4.2: 4 线程 LT vs ET × 短/长连接 × 100/1000 连接，各 3 轮 =====
for mode in lt et; do
  clean
  nohup ./echo-mt-server 9988 4 "$mode" > /tmp/mt42.log 2>&1 &
  sleep 3
  cnt=$(ss -tln | grep -c 9988)
  echo "[42 $mode] listening=$cnt"
  timeout 30 ./echo-kp-bench 127.0.0.1 9988 100 10 --mode long > /dev/null 2>&1
  for c in 100 1000; do
    for len in short long; do
      for i in 1 2 3; do
        timeout 60 ./echo-kp-bench 127.0.0.1 9988 "$c" 10 --mode "$len" \
          > results42/${mode}-c${c}-${len}-r$i.txt 2>&1
        echo "  42 ${mode}-c${c}-${len}-r$i size=$(stat -c%s results42/${mode}-c${c}-${len}-r$i.txt)"
      done
    done
  done
done

# ===== 4.3: 4 线程 LT 连接数扫描 100/500/1000/2000/5000 × 短/长，各 3 轮 =====
clean
nohup ./echo-mt-server 9988 4 lt > /tmp/mt43.log 2>&1 &
sleep 3
cnt=$(ss -tln | grep -c 9988)
echo "[43 lt] listening=$cnt"
timeout 30 ./echo-kp-bench 127.0.0.1 9988 100 10 --mode long > /dev/null 2>&1
for c in 100 500 1000 2000 5000; do
  for len in short long; do
    for i in 1 2 3; do
      timeout 90 ./echo-kp-bench 127.0.0.1 9988 "$c" 10 --mode "$len" \
        > results43/scan-${c}-${len}-r$i.txt 2>&1
      echo "  43 scan-${c}-${len}-r$i size=$(stat -c%s results43/scan-${c}-${len}-r$i.txt)"
    done
  done
done

clean
echo "=== 42+43 DONE ==="
