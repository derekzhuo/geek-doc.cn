#!/usr/bin/env bash
# LP15 iodepth 1/2/4/8/16/32 扫档，每档 30s，共 3 轮
set -u
cd "$(dirname "$0")"
LOG=~/logs/lp15
mkdir -p "$LOG"
DEV=$(lsblk -no PKNAME "$(df --output=source / | tail -1)" 2>/dev/null | head -1)
[ -z "$DEV" ] && DEV=$(lsblk -dno NAME | grep -v loop | grep -v sr | head -1)
echo "== kernel =="; uname -a
echo "== block device =="; lsblk -d -o NAME,SIZE,ROTA,TYPE,MODEL | grep -v loop
echo "== scheduler ($DEV) =="; cat "/sys/block/$DEV/queue/scheduler"
echo "== nr_hw_queues =="; ls "/sys/block/$DEV/mq/" | wc -l
echo "== fio version =="; fio --version

for round in 1 2 3; do
  for d in 1 2 4 8 16 32; do
    echo "---- round=$round iodepth=$d ----"
    IOD=$d fio iodepth.fio --output-format=json | tee "$LOG/iodepth-r$round-d$d.json" | \
      python3 -c "
import json,sys
r=json.load(sys.stdin)['jobs'][0]['read']
lat=r['clat_ns']
print(f\"iops={r['iops']:.1f} bw_KiB/s={r['bw']} p50={lat['percentile']['50.000000']} p99={lat['percentile']['99.000000']} p999={lat['percentile']['99.900000']} max={lat['max']}\")
"
  done
done
rm -f fio-test.bin
echo "== DONE =="
