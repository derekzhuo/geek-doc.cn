#!/bin/bash
set -euo pipefail
label=$1
duration=$2
perf_seconds=${3:-0}
out="$HOME/e0data/$label"
mkdir -p "$out"
rm -f "$out/done"
rx_packets() { awk '$1=="eth0:" {print $3}' /proc/net/dev; }
tx_packets() { awk '$1=="eth0:" {print $11}' /proc/net/dev; }
start=$(date +%s)
last_rx=$(rx_packets)
last_tx=$(tx_packets)
triggered=0
while [ $(( $(date +%s) - start )) -lt 300 ]; do
  sleep 1
  rx=$(rx_packets); tx=$(tx_packets)
  pps=$((rx + tx - last_rx - last_tx))
  last_rx=$rx; last_tx=$tx
  if [ "$pps" -gt 30000 ]; then
    printf 'trigger_unix=%s\ntrigger_pps=%s\n' "$(date +%s)" "$pps" > "$out/trigger.txt"
    triggered=1
    break
  fi
done
if [ "$triggered" -ne 1 ]; then
  echo 'PPS trigger timed out' > "$out/error.txt"
  touch "$out/done"
  exit 1
fi
ethtool -S eth0 > "$out/eth-before.txt"
cat /proc/softirqs > "$out/softirqs-before.txt"
LC_ALL=C sar -n DEV 1 "$duration" > "$out/sar.txt" 2> "$out/sar.err" & sar_pid=$!
LC_ALL=C mpstat -P ALL 1 "$duration" > "$out/mpstat.txt" 2> "$out/mpstat.err" & mp_pid=$!
if [ "$perf_seconds" -gt 0 ]; then
  sudo perf record -a -g -F 199 -o "$out/perf.data" -- sleep "$perf_seconds" > "$out/perf-record.txt" 2>&1 & perf_pid=$!
fi
wait "$sar_pid"
wait "$mp_pid"
if [ "$perf_seconds" -gt 0 ]; then
  wait "$perf_pid"
  sudo chown "$USER:$USER" "$out/perf.data"
  perf report --stdio -i "$out/perf.data" --percent-limit 0.5 > "$out/perf-report.txt" 2> "$out/perf-report.err"
fi
ethtool -S eth0 > "$out/eth-after.txt"
cat /proc/softirqs > "$out/softirqs-after.txt"
date +%s > "$out/end-unix.txt"
touch "$out/done"
