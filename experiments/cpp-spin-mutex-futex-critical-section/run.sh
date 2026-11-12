#!/usr/bin/env bash
# 三锁临界区扫档编排：
#   完整基准连跑 5 次，对每个 lock×threads×cs 组合的 ns_op 取五次中位；
#   再用 sudo perf stat 采 w1 与 sleep100us 两级、4 线程下三锁的上下文切换等事件。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-5}"
RESULT_FILE="results.txt"

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make clean >/dev/null
make >/dev/null

log "# 三锁临界区长度扫档基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# host: $(hostname) | kernel: $(uname -r)"
log "# distro: $(lsb_release -ds 2>/dev/null || echo unknown)"
log "# compiler: $(g++ --version | head -1)"
log "# cpu: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
lscpu | grep -E '^CPU\(s\)|Thread|Core|Socket|L1d|L2|L3|NUMA node' | sed 's/^/# lscpu: /' | tee -a "$RESULT_FILE"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log "===== 完整基准 ${RUNS} 次进程运行（每次 3 锁 × 6 临界区级 × 4 线程档） ====="
for i in $(seq 1 "$RUNS"); do
    ./bin/lock_bench > "$TMP/run-${i}.txt"
    log "--- 第 ${i} 次 ---"
    cat "$TMP/run-${i}.txt" | tee -a "$RESULT_FILE"
done

log ""
log "===== 五次运行 ns_op 中位汇总（按 lock/cs/threads） ====="
grep -h '^RESULT' "$TMP"/run-*.txt | awk '{
    split($2,a,"="); split($3,b,"="); split($4,c,"=")
    # 正常布局数值在 $6；数值超 %10.2f 宽度时会贴住 ns_op= 落在 $5，两种都兼容
    v = ($5 ~ /=$/) ? $6 : substr($5, index($5, "=") + 1)
    key=a[2] SUBSEP c[2] SUBSEP b[2]
    vals[key] = (key in vals ? vals[key] " " v : v)
    order[key] = (seen[key]++ ? order[key] : NR SUBSEP key)
}
END {
    for (k in vals) {
        n = split(vals[k], arr, " ")
        for (i = 1; i <= n; ++i) for (j = i + 1; j <= n; ++j)
            if (arr[j] < arr[i]) { t = arr[i]; arr[i] = arr[j]; arr[j] = t }
        split(k, kk, SUBSEP)
        printf "MEDIAN lock=%-8s cs=%-11s threads=%d ns_op=%10.2f\n", kk[1], kk[2], kk[3], arr[int((n+1)/2)]
    }
}' | sort | tee -a "$RESULT_FILE"

log ""
log "===== perf stat 佐证（4 线程，w1 与 sleep100us，sudo） ====="
for lock in spin mutex adaptive; do
    for cs in w1 sleep100us; do
        log "--- FILTER_LOCK=${lock} FILTER_CS=${cs} FILTER_THREADS=4 ---"
        sudo perf stat -e context-switches,page-faults,cache-misses,instructions,cycles \
            env FILTER_LOCK="$lock" FILTER_CS="$cs" FILTER_THREADS=4 \
            ./bin/lock_bench 2>&1 | tee -a "$RESULT_FILE"
        log ""
    done
done

log "done"
