#!/usr/bin/env bash
# LP12 脏页回写调参：三档 dirty_background_ratio/dirty_ratio 下的突发写卡顿对照
set -u
cd "$(dirname "$0")"
echo '$ sudo bash run.sh'
LOG=~/logs/lp12
mkdir -p "$LOG"
make >/dev/null || exit 1

VM=/proc/sys/vm
ORIG_BG=$(cat "$VM/dirty_background_ratio")
ORIG_RATIO=$(cat "$VM/dirty_ratio")
reset_dirty() {
  echo "$ORIG_BG" | sudo tee "$VM/dirty_background_ratio" >/dev/null
  echo "$ORIG_RATIO" | sudo tee "$VM/dirty_ratio" >/dev/null
}
trap reset_dirty EXIT

echo "== kernel =="; uname -a
echo "== defaults: dirty_background_ratio=$ORIG_BG dirty_ratio=$ORIG_RATIO =="
grep -E 'nr_dirty |nr_writeback |pgpgout' /proc/vmstat

# 档位名 bg:ratio
run_case() {
  local tag="$1" bg="$2" ratio="$3"
  echo "########## case=$tag bg=$bg ratio=$ratio ##########"
  echo "$bg" | sudo tee "$VM/dirty_background_ratio" >/dev/null
  echo "$ratio" | sudo tee "$VM/dirty_ratio" >/dev/null
  echo "[active] bg=$(cat $VM/dirty_background_ratio) ratio=$(cat $VM/dirty_ratio)"
  sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
  grep -E 'nr_dirty |nr_writeback |pgpgout' /proc/vmstat | tee "$LOG/$tag-vmstat-before.txt"
  vmstat 1 > "$LOG/$tag-vmstat.log" &
  local vmpid=$!
  ./dirty_bench dirty.bin 2560 32 | tee "$LOG/$tag-bench.log"
  kill "$vmpid" 2>/dev/null
  sync
  grep -E 'nr_dirty |nr_writeback |pgpgout' /proc/vmstat | tee "$LOG/$tag-vmstat-after.txt"
  rm -f dirty.bin
}

run_case loose 10 20
run_case medium 5 10
run_case tight 0 5

echo "== DONE =="
