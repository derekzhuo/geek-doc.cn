#!/usr/bin/env bash
# placement new 对象池基准编排：
#   -O2 与 -O0 两个二进制各跑 7 次，按场景/实现取 ns/次中位；
#   另用 /usr/bin/time -l 固定 O2 二进制的 RSS、缺页与上下文切换。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make clean >/dev/null
make >/dev/null

log "# placement new 对象池基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $(clang++ --version | head -1)"
log "# flags: -std=c++17 -Wall -Wextra；O2/O0 各运行 ${RUNS} 次取中位"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for opt in O2 O0; do
    for i in $(seq 1 "$RUNS"); do
        "./bin/bench-${opt}" > "$TMP/${opt}-${i}.txt"
    done
done

log "===== -O2 首次完整输出 ====="
cat "$TMP/O2-1.txt" | tee -a "$RESULT_FILE"
log ""

# 抽取每个 [场景|实现] 的七轮 ns/次，输出中位
extract() {
    local opt="$1" tag="$2" impl="$3"
    local vals=()
    for i in $(seq 1 "$RUNS"); do
        v=$(grep "\\[${tag}|${impl}\\]" "$TMP/${opt}-${i}.txt" \
            | head -1 | sed -E 's/.*中位 ([0-9.]+) ns.*/\1/')
        vals+=("$v")
    done
    median "${vals[@]}"
}

log "===== 七轮中位汇总（ns/次） ====="
for opt in O2 O0; do
    for tag in churn steady; do
        for impl in pool "raw "; do
            key=$(echo "$impl" | tr -d ' ')
            m=$(extract "$opt" "$tag" "$impl")
            log "[${opt}][${tag}|${key}] 中位 ${m} ns/次，百万次约 $(perl -e 'printf "%.3f", $ARGV[0]' "$m") ms"
        done
    done
done
log ""

log "===== -O0 首次完整输出（分配/构造计数与耗尽行为两档一致） ====="
cat "$TMP/O0-1.txt" | tee -a "$RESULT_FILE"
log ""

log "===== /usr/bin/time -l 系统侧佐证（O2 单次运行） ====="
/usr/bin/time -l ./bin/bench-O2 > "$TMP/time-stdout.txt" 2> "$TMP/time.txt" || true
grep -E "maximum resident set size|page reclaims|page faults|voluntary context switches|involuntary context switches" \
    "$TMP/time.txt" | tee -a "$RESULT_FILE"

log ""
log "===== 结束 ====="
