#!/usr/bin/env bash
# STREAM 风格带宽基准编排：
#   OMP_NUM_THREADS=1/2 各跑 7 次，按四内核的「最佳 GB/s」取七次中位；
#   另用 sudo perf stat 采 page-faults/context-switches/cache-misses/instructions/cycles。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make clean >/dev/null
make >/dev/null

log "# STREAM 内存带宽基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# host: $(hostname) | kernel: $(uname -r)"
log "# distro: $(lsb_release -ds 2>/dev/null || echo unknown)"
log "# compiler: $(gcc --version | head -1)"
log "# flags: -O3 -std=c11 -fopenmp -march=native -DSTREAM_N=10000000 -DNTIMES=20"
log "# cpu: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
log "# threads 扫档: 1,2（本机 1 核 2 线程，2 即 SMT 兄弟线程）"
lscpu | grep -E '^CPU\(s\)|Thread|Core|Socket|L1d|L2|L3|NUMA node' | sed 's/^/# lscpu: /' | tee -a "$RESULT_FILE"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for threads in 1 2; do
    log "===== OMP_NUM_THREADS=${threads}：${RUNS} 次进程运行（每次含 20 轮，首轮预热） ====="
    for i in $(seq 1 "$RUNS"); do
        OMP_NUM_THREADS="$threads" ./bin/stream_bench > "$TMP/t${threads}-${i}.txt"
        log "--- 第 ${i} 次 ---"
        cat "$TMP/t${threads}-${i}.txt" | tee -a "$RESULT_FILE"
    done

    log ""
    log "===== 七次运行的最佳 GB/s 中位汇总（threads=${threads}） ====="
    for kernel in Copy Scale Add Triad; do
        med=$(grep "^${kernel} " "$TMP"/t${threads}-*.txt | awk '{print $2}' | sort -n \
              | perl -e '@v=<>; chomp @v; print $v[int(@v/2)]')
        log "$(printf '%-6s 中位最佳带宽 %8.2f GB/s' "$kernel" "$med")"
    done
    log ""
done

log "===== perf stat 系统侧佐证（每线程档一次，sudo） ====="
for threads in 1 2; do
    log "--- OMP_NUM_THREADS=${threads} ---"
    sudo perf stat -e page-faults,context-switches,cache-misses,instructions,cycles \
        env OMP_NUM_THREADS="$threads" ./bin/stream_bench 2>&1 | tee -a "$RESULT_FILE"
    log ""
done

log "done"
