#!/usr/bin/env bash
# LP07: cgroup v2 memory.high / memory.max 回收、PSI 与 OOM 行为对照
set -u
trap 'rc=$?; echo "TRAP exit rc=$rc line=$LINENO cmd=$BASH_COMMAND" >&2' EXIT
ROOT=/sys/fs/cgroup/pp-lp07
LOGDIR="$(dirname "$0")/logs-lp07"
mkdir -p "$LOGDIR"

if [ "$(id -u)" -ne 0 ]; then echo "need root"; exit 1; fi

reset_group() {
  if [ -d "$ROOT" ]; then
    while read -r p; do [ -n "$p" ] && kill -9 "$p" 2>/dev/null || true; done < "$ROOT/cgroup.procs"
    sleep 0.3
    rmdir "$ROOT" 2>/dev/null || true
  fi
  mkdir -p "$ROOT"
  echo +memory > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
}

snapshot() { # name
  echo "---- $1: memory.events ----"
  cat "$ROOT/memory.events"
  echo "---- $1: memory.pressure ----"
  cat "$ROOT/memory.pressure"
  echo "---- $1: memory.current / max / high / swap.max ----"
  for f in memory.current memory.max memory.high memory.swap.max; do printf '%s=' "$f"; cat "$ROOT/$f"; done
}

psi_sampler() { # logfile
  local out=$1
  : > "$out"
  while [ -d "$ROOT" ]; do
    local ts some full
    ts=$(date +%s.%N)
    some=$(awk '/^some/{for(i=1;i<=NF;i++)if($i~/^total=/){sub("total=","",$i);print $i}}' "$ROOT/memory.pressure")
    full=$(awk '/^full/{for(i=1;i<=NF;i++)if($i~/^total=/){sub("total=","",$i);print $i}}' "$ROOT/memory.pressure")
    echo "$ts some_total_us=$some full_total_us=$full" >> "$out"
    sleep 0.5 || break
  done
}

# 限制必须在本函数自己的 reset_group 之后写入，否则会随 rmdir/mkdir 被清掉
run_phase() { # name setup-commands workload_args...
  local name=$1 setup=$2; shift 2
  echo "==================== PHASE $name ===================="
  reset_group
  eval "$setup"
  snapshot "$name before" | tee "$LOGDIR/$name.before.txt"
  psi_sampler "$LOGDIR/$name.psi.log" & sp=$!
  local t0
  t0=$(date +%s.%N)
  ( echo $BASHPID > "$ROOT/cgroup.procs"; echo "member_cgroup=$(cat /proc/self/cgroup)"; \
    echo "effective: memory.max=$(cat $ROOT/memory.max) memory.high=$(cat $ROOT/memory.high) memory.swap.max=$(cat $ROOT/memory.swap.max)"; \
    exec ./memtouch "$@" ) 2>&1 | tee "$LOGDIR/$name.workload.log"
  local rc=${PIPESTATUS[0]}
  local t1
  t1=$(date +%s.%N)
  kill "$sp" 2>/dev/null
  echo "phase=$name exit=$rc elapsed_s=$(echo "$t1-$t0" | bc)" | tee "$LOGDIR/$name.summary.txt"
  snapshot "$name after" | tee "$LOGDIR/$name.after.txt"
}

dmesg -C || true
gcc -O2 -o memtouch memtouch.c

if ! swapon --show | grep -q swapfile; then
  fallocate -l 2G /swapfile-lp && chmod 600 /swapfile-lp && mkswap /swapfile-lp >/dev/null && swapon /swapfile-lp
fi
swapon --show

# A：无限制基线，500 MiB 重复字节页
run_phase A "echo max > $ROOT/memory.high" 500 zero

# B：memory.high=300M 软限 -> 节流回收但存活
run_phase B "echo 314572800 > $ROOT/memory.high" 500 zero

# C：memory.max=300M 且允许 swap -> 回收+换出，硬限下的停顿
run_phase C "echo 314572800 > $ROOT/memory.max; echo max > $ROOT/memory.swap.max" 500 zero

# D：memory.max=300M 且 swap.max=0 -> 触限即 cgroup OOM kill
run_phase D "echo 314572800 > $ROOT/memory.max; echo 0 > $ROOT/memory.swap.max" 500 zero

echo "==================== dmesg (OOM 证据) ===================="
dmesg | grep -E -i 'oom|killed process|out of memory' | tee "$LOGDIR/d-oom-dmesg.log"
echo "ALL DONE"
