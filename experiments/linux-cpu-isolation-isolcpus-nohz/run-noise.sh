#!/bin/bash
# CPU0 忙等噪声下的三组对照。用法: sudo run-noise.sh <baseline|isolated>
set -e
MODE=$1
cd "$(dirname "$0")"
gcc -O2 -pthread iso_lat.c -o iso_lat
gcc -O2 busy.c -o busy
echo "##### NOISE MODE=$MODE $(date -Is) #####"
cat /sys/devices/system/cpu/isolated
taskset -c 0 ./busy &
BPID=$!
sleep 1
echo "noise pid=$BPID on cpu0, psr=$(ps -o psr= -p $BPID)"
for pair in 0-0 0-1 1-1; do
  a=${pair%-*}; b=${pair#*-}
  echo "--- pair $pair under cpu0 noise (3 runs x 200000) ---"
  echo "irq.before.$pair:"; cat /proc/interrupts
  for rep in 1 2 3; do ./iso_lat "$a" "$b" 200000 10000; done
  echo "irq.after.$pair:"; cat /proc/interrupts
done
kill -9 $BPID
echo "DONE_NOISE_$MODE"
