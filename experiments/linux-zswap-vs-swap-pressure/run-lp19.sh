#!/usr/bin/env bash
# LP19: zswap 开/关 × 可压缩(重复字节)/不可压缩(随机) 四格对照
set -u
trap 'rc=$?; echo "TRAP exit rc=$rc line=$LINENO cmd=$BASH_COMMAND" >&2' EXIT
ROOT=/sys/fs/cgroup/pp-lp19
LOGDIR="$(dirname "$0")/logs-lp19"
mkdir -p "$LOGDIR"
if [ "$(id -u)" -ne 0 ]; then echo "need root"; exit 1; fi

SWAP=/swapfile-lp
if ! swapon --show | grep -q "$SWAP"; then
  fallocate -l 2G "$SWAP" && chmod 600 "$SWAP" && mkswap "$SWAP" >/dev/null
fi

echo "zswap params: enabled=$(cat /sys/module/zswap/parameters/enabled) compressor=$(cat /sys/module/zswap/parameters/compressor) zpool=$(cat /sys/module/zswap/parameters/zpool)"

reset_env() { # enabled Y|N
  swapoff -a 2>/dev/null
  echo "$1" > /sys/module/zswap/parameters/enabled
  swapon "$SWAP"
  if [ -d "$ROOT" ]; then
    while read -r p; do [ -n "$p" ] && kill -9 "$p" 2>/dev/null || true; done < "$ROOT/cgroup.procs"
    sleep 0.3
    rmdir "$ROOT" 2>/dev/null || true
  fi
  mkdir -p "$ROOT"
  echo 1258291200 > "$ROOT/memory.max"        # 1200 MiB
  echo 1258291200 > "$ROOT/memory.swap.max"   # 再给 1200 MiB swap 额度
  echo 1 > /proc/sys/vm/drop_caches
}

zstats() {
  for f in stored_pages pool_total_size written_back_pages duplicate_entry; do
    printf '%s=%s ' "$f" "$(cat /sys/kernel/debug/zswap/$f 2>/dev/null || echo NA)"
  done; echo
}

# 运行中采样：zswap 条目随进程退出即释放，事后采样只剩零头，必须边跑边记
sampler() { # outfile wpid
  local out=$1 wpid=$2
  : > "$out"
  while kill -0 "$wpid" 2>/dev/null; do
    local ts cur swcur pswp zs
    ts=$(date +%s.%N)
    cur=$(cat "$ROOT/memory.current")
    swcur=$(cat "$ROOT/memory.swap.current" 2>/dev/null || echo NA)
    pswp=$(awk '/pswpout/{print $2}' /proc/vmstat)
    zs=$(cat /sys/kernel/debug/zswap/stored_pages 2>/dev/null || echo NA)
    echo "$ts mem.current=$cur swap.current=$swcur pswpout=$pswp zswap.stored=$zs" >> "$out"
    sleep 0.5
  done
}

run_cell() { # zswap(Y|N) payload(zero|random)
  local z=$1 payload=$2
  local name="z${z}-${payload}"
  echo "==================== CELL $name ===================="
  reset_env "$z"
  swapon --show
  local pswp0 some0 full0 z0 t0
  pswp0=$(awk '/pswpout/{print $2}' /proc/vmstat)
  some0=$(awk '/^some/{for(i=1;i<=NF;i++)if($i~/^total=/){sub("total=","",$i);print $i}}' "$ROOT/memory.pressure")
  full0=$(awk '/^full/{for(i=1;i<=NF;i++)if($i~/^total=/){sub("total=","",$i);print $i}}' "$ROOT/memory.pressure")
  z0=$(zstats)
  t0=$(date +%s.%N)
  ( echo $BASHPID > "$ROOT/cgroup.procs"; echo "member_cgroup=$(cat /proc/self/cgroup)"; \
    echo "effective: memory.max=$(cat $ROOT/memory.max) memory.swap.max=$(cat $ROOT/memory.swap.max)"; \
    exec ./memtouch 1800 "$payload" 64 ) 2>&1 | tee "$LOGDIR/$name.workload.log" &
  local wpid=$!
  sampler "$LOGDIR/$name.sampler.log" "$wpid"
  wait "$wpid"; local rc=$?
  local t1 pswp1 some1 full1 z1
  t1=$(date +%s.%N)
  pswp1=$(awk '/pswpout/{print $2}' /proc/vmstat)
  some1=$(awk '/^some/{for(i=1;i<=NF;i++)if($i~/^total=/){sub("total=","",$i);print $i}}' "$ROOT/memory.pressure")
  full1=$(awk '/^full/{for(i=1;i<=NF;i++)if($i~/^total=/){sub("total=","",$i);print $i}}' "$ROOT/memory.pressure")
  z1=$(zstats)
  local peak_swap peak_zswap
  peak_swap=$(awk -F'[= ]' '/swap.current/{if($5>m)m=$5} END{print m+0}' "$LOGDIR/$name.sampler.log")
  peak_zswap=$(awk -F'[= ]' '/zswap.stored/{if($9>m)m=$9} END{print m+0}' "$LOGDIR/$name.sampler.log")
  {
    echo "cell=$name exit=$rc elapsed_s=$(echo "$t1-$t0" | bc)"
    echo "pswpout_delta=$((pswp1-pswp0)) pages"
    echo "psi_some_delta_us=$((some1-some0)) psi_full_delta_us=$((full1-full0))"
    echo "peak_swap_current=$peak_swap bytes peak_zswap_stored=$peak_zswap pages"
    echo "zswap_before: $z0"
    echo "zswap_after:  $z1 (进程退出后条目即释放，看峰值)"
    echo "memory.events:"; cat "$ROOT/memory.events"
  } | tee "$LOGDIR/$name.summary.txt"
}

gcc -O2 -o memtouch memtouch.c
run_cell Y zero
run_cell Y random
run_cell N zero
run_cell N random
echo "ALL DONE"
