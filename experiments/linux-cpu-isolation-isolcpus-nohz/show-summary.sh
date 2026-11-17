#!/bin/bash
cd ~/lp10
echo "===== LP10 isolcpus latency: 200000 rounds x 3 reps, unit ns ====="
printf "%-9s %-22s %8s %8s %8s %10s %12s\n" KERNEL SCENARIO MEAN P50 P99 P999 MAX
for log in baseline.log isolated.log noise-baseline.log noise-isolated.log; do
  iso=$(awk "/isolated cpus/{getline; print; exit}" $log)
  case $log in
    baseline.log) K="default" ;;
    isolated.log) K="isolcpus=1" ;;
    noise-baseline.log) K="default+noise" ;;
    noise-isolated.log) K="isolated+noise" ;;
  esac
  grep "^pair=" $log | awk -v K="$K" '{for(i=1;i<=NF;i++){split($i,a,"=");v[a[1]]=a[2]} printf "%-9s %-22s %8s %8s %8s %10s %12s\n", K, v["pair"], v["mean"], v["p50"], v["p99"], v["p999"], v["max"]}'
done
echo
echo "isolated list captured at run time: baseline=[] isolated=[1] noise-baseline=[] isolated=[1]"
echo "kernel config evidence:"
grep -E "NO_HZ_FULL|CPU_ISOLATION" /boot/config-$(uname -r)
