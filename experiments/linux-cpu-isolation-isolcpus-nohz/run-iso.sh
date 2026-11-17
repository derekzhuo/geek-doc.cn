#!/bin/bash
# LP10 隔离/共享核 ping-pong 延迟对照。用法: sudo run-iso.sh <baseline|isolated>
set -e
MODE=$1
cd "$(dirname "$0")"
gcc -O2 -pthread iso_lat.c -o iso_lat
echo "##### MODE=$MODE $(date -Is) #####"
echo "--- cmdline ---"; cat /proc/cmdline
echo "--- isolated cpus ---"; cat /sys/devices/system/cpu/isolated
echo "--- nohz_full cpus ---"; cat /sys/devices/system/cpu/nohz_full 2>/dev/null || echo "(not available: CONFIG_NO_HZ_FULL unset)"
grep -E "NO_HZ_FULL|RCU_NOCB|CPU_ISOLATION" /boot/config-$(uname -r) || true
for pair in 0-0 0-1 1-1; do
  a=${pair%-*}; b=${pair#*-}
  echo "--- pair $pair (3 runs x 200000 rounds) ---"
  echo "irq.before.$pair:"; cat /proc/interrupts
  for rep in 1 2 3; do
    ./iso_lat "$a" "$b" 200000 10000
  done
  echo "irq.after.$pair:"; cat /proc/interrupts
done
echo "--- perf stat on pair 1-1 ---"
perf stat -e context-switches,cpu-migrations,minor-faults,page-faults ./iso_lat 1 1 200000 10000 2>&1
echo "DONE_$MODE"
