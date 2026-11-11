#!/usr/bin/env bash
# shared_ptr 引用计数争用基准编排：
#   线程扫档 1/2/4/6/8/12 × 四模式，整程序跑 7 次，按格取耗时中位；
#   另从反汇编统计 lock 前缀原子指令，作为引用计数原子操作的机制证据。
set -euo pipefail
cd "$(dirname "$0")"

CXX_USED="${CXX:-clang++}"
RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

log "# shared_ptr 引用计数争用基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $($CXX_USED --version | head -1)"
log "# flags: -O2 -std=c++17 -Wall；总任务 400 万，线程扫档 1/2/4/6/8/12，运行 ${RUNS} 次"
log ""

make clean >/dev/null
make CXX="$CXX_USED" >/dev/null

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for i in $(seq 1 "$RUNS"); do
    ./bin/bench >> "$TMP/raw.txt"
done
# 预热格 ops=100000，正式扫档为 400 万级，过滤后所有统计只看正式行。
grep -v "ops=100000 " "$TMP/raw.txt" > "$TMP/timed.txt"

log "===== 首次完整扫档输出 ====="
awk 'NR<=26' "$TMP/timed.txt" | tee -a "$RESULT_FILE"

log ""
log "===== 各格 7 次耗时中位 (ms) ====="
for mode in unique raw shared_ro shared_copy; do
    for nth in 1 2 4 6 8 12; do
        vals="$(grep "^mode=${mode} " "$TMP/timed.txt" | grep -E "threads= *${nth} " | sed 's/.*elapsed_ms= *\([0-9.]*\).*/\1/')"
        line="$(grep "^mode=${mode} " "$TMP/timed.txt" | grep -E "threads= *${nth} " | head -1)"
        ns="$(echo "$line" | sed 's/.*ns_per_op= *\([0-9.]*\).*/\1/')"
        log "$(printf '%-12s threads=%2d median_ms=%9s ns_per_op(first)=%s' "$mode" "$nth" "$(median $vals)" "$ns")"
    done
done

log ""
log "===== 反汇编中的 lock 前缀原子指令（引用计数增减） ====="
lock_total="$(otool -tvV bin/bench | awk '$NF=="lock"' | wc -l | tr -d ' ')"
log "lock 前缀指令总数: ${lock_total}"
otool -tvV bin/bench | awk '$NF=="lock"{getline next_line; print "lock " next_line}' \
    | sed 's/^[0-9a-f]*//' | sort | uniq -c | sort -rn | awk 'NR<=6' | tee -a "$RESULT_FILE"
log "done"
