#!/usr/bin/env bash
# LP03 ptmalloc/jemalloc/tcmalloc 多线程争用：线程 1/2/4 × 三轮，附 perf stat 争用旁证
set -u
cd "$(dirname "$0")"
echo '$ sudo -E bash run.sh'
LOG=results
mkdir -p "$LOG"
RUNLOG="$LOG/run-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$RUNLOG") 2>&1

ROUNDS=${ROUNDS:-3}
ITERS=${ITERS:-2000000}
JEMALLOC=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
TCMALLOC=/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4

echo "== kernel =="; uname -a
echo "== allocator versions =="
dpkg -l | grep -E 'libjemalloc-dev|libgoogle-perftools|libtcmalloc-minimal4' | awk '{print $2, $3}'
ldd --version | head -1
echo "== build =="
make clean >/dev/null 2>&1 || true
make || exit 1

echo "== preload check =="
ldd ./alloc_bench | grep -E 'jemalloc|tcmalloc' || echo "glibc(ptmalloc): no external malloc preloaded"
LD_PRELOAD="$JEMALLOC" ldd ./alloc_bench | grep jemalloc
LD_PRELOAD="$TCMALLOC" ldd ./alloc_bench | grep tcmalloc

CSV="$LOG/summary.csv"
echo "allocator,threads,round,wall_ms,ops_per_s,p50_ns,p99_ns,p999_ns" > "$CSV"

run_matrix() {
  local name="$1" preload="$2"
  for t in 1 2 4; do
    for r in $(seq 1 "$ROUNDS"); do
      local line
      line=$(LD_PRELOAD="$preload" ./alloc_bench -t "$t" -n "$ITERS")
      echo "alloc=$name threads=$t round=$r $line"
      echo "$line" | awk -v name="$name" -v t="$t" -v r="$r" '
        {
          for (i=1;i<=NF;i++) { split($i,kv,"="); v[kv[1]]=kv[2] }
          printf "%s,%s,%s,%s,%s,%s,%s,%s\n", name, t, r, v["wall_ms"], v["ops_per_s"], v["p50_ns"], v["p99_ns"], v["p999_ns"]
        }' >> "$CSV"
    done
  done
}

run_matrix glibc ""
run_matrix jemalloc "$JEMALLOC"
run_matrix tcmalloc "$TCMALLOC"

echo "== perf stat contention evidence (threads=4, one run each) =="
for pair in "glibc:" "jemalloc:$JEMALLOC" "tcmalloc:$TCMALLOC"; do
  name="${pair%%:*}"; preload="${pair#*:}"
  echo "-- alloc=$name"
  sudo perf stat -e task-clock,context-switches,cpu-migrations,page-faults \
    env LD_PRELOAD="$preload" ./alloc_bench -t 4 -n "$ITERS" 2>&1 | tee -a "$LOG/perf-t4.log" | tail -12
done
echo "== DONE =="
