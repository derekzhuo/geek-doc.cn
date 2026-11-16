#!/usr/bin/env bash
# LP13 页缓存命中率：冷/热全文件顺序读 + 缓存命中下缓冲随机读与 direct 随机读对照
set -u
cd "$(dirname "$0")"
LOG=~/logs/lp13
mkdir -p "$LOG"
make >/dev/null || exit 1

echo "== kernel =="; uname -a
echo "== meminfo baseline =="; grep -E '^(MemTotal|Cached|Dirty):' /proc/meminfo
echo "== create 512m dataset (direct write, 不污染页缓存) =="
fio --name=prep --filename=cache-test.bin --ioengine=libaio --rw=write --bs=1m \
    --size=512m --direct=1 --group_reporting | tail -3
sync

run_case() {
  local tag="$1"; shift
  echo "---- case=$tag ----"
  echo "[meminfo before]"; grep -E '^(Cached|Dirty):' /proc/meminfo
  echo "[diskstats before]"; grep ' vda ' /proc/diskstats
  ./mincore_check cache-test.bin | tee -a "$LOG/mincore.log"
  "$@" --output-format=json | tee "$LOG/$tag.json" | python3 -c "
import json,sys
r=json.load(sys.stdin)['jobs'][0]['read']
lat=r['clat_ns']['percentile']
print(f\"iops={r['iops']:.1f} bw_MiB/s={r['bw']/1024:.2f} p50_us={lat['50.000000']/1000:.1f} p99_us={lat['99.000000']/1000:.1f}\")
"
  echo "[meminfo after]"; grep -E '^(Cached|Dirty):' /proc/meminfo
  echo "[diskstats after]"; grep ' vda ' /proc/diskstats
  ./mincore_check cache-test.bin | tee -a "$LOG/mincore.log"
}

for round in 1 2 3; do
  echo "########## round=$round ##########"
  sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
  run_case "cold-seq-r$round"      env RW=read      DIRECT=0 IOD=1 TIME_BASED=0 RUNTIME=0  fio read.fio
  run_case "hot-seq-r$round"       env RW=read      DIRECT=0 IOD=1 TIME_BASED=0 RUNTIME=0  fio read.fio
  run_case "rand-cached-r$round"   env RW=randread  DIRECT=0 IOD=8 TIME_BASED=1 RUNTIME=20 fio read.fio
  run_case "rand-direct-r$round"   env RW=randread  DIRECT=1 IOD=8 TIME_BASED=1 RUNTIME=20 fio read.fio
done
rm -f cache-test.bin
echo "== DONE =="
