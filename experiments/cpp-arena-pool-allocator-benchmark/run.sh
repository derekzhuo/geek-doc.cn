#!/usr/bin/env bash
# arena 内存池基准编排：
#   -O2 与 -O0 两个二进制各跑 7 次，按 [ST|..] / [MT|..] 行取中位；
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

log "# arena 内存池基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $(clang++ --version | head -1)"
log "# flags: -std=c++17 -Wall -Wextra -pthread；O2/O0 各运行 ${RUNS} 次取中位"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for opt in O2 O0; do
    for i in $(seq 1 "$RUNS"); do
        "./bin/bench-${opt}" "$opt" > "$TMP/${opt}-${i}.txt"
    done
done

log "===== -O2 首次完整输出 ====="
cat "$TMP/O2-1.txt" | tee -a "$RESULT_FILE"
log ""

# 抽取同一标记行 7 轮的主指标：
# ST 行取 ns/对象；MT 行取 ns/对象（第 2 个数值字段）
# ST 行形如 [ST|32B|raw]   中位   73.52 ns/对象  样本 ...，第 3 个字段即中位
extract_st() {
    local opt="$1" tag="$2"
    local vals=()
    for i in $(seq 1 "$RUNS"); do
        v=$(grep -F "[$tag]" "$TMP/${opt}-${i}.txt" | head -1 | awk '{print $3}')
        vals+=("$v")
    done
    median "${vals[@]}"
}
# MT 行形如 [MT|1t|raw-batch] 总 14.526 ms 72.63 ns/对象 ...，第 5 个字段即 ns/对象
extract_mt() {
    local opt="$1" tag="$2"
    local vals=()
    for i in $(seq 1 "$RUNS"); do
        v=$(grep -F "[$tag]" "$TMP/${opt}-${i}.txt" | head -1 | awk '{print $5}')
        vals+=("$v")
    done
    median "${vals[@]}"
}

log "===== 七轮中位汇总：单线程 ns/对象 ====="
for opt in O2 O0; do
    for sz in 32 128 256; do
        for kind in raw arena; do
            tag="ST|${sz}B|${kind}"
            m=$(extract_st "$opt" "$tag")
            log "[${opt}][${tag}] 中位 ${m} ns/对象"
        done
    done
done
log ""

log "===== 七轮中位汇总：多线程 ns/对象 ====="
for opt in O2 O0; do
    for t in 1 2 4 8; do
        for kind in raw-batch arena-thread arena-shared; do
            tag="MT|${t}t|${kind}"
            m=$(extract_mt "$opt" "$tag")
            log "[${opt}][${tag}] 中位 ${m} ns/对象"
        done
    done
done
log ""

log "===== /usr/bin/time -l 系统侧资源（O2 单次） ====="
/usr/bin/time -l ./bin/bench-O2 O2 > "$TMP/time.txt" 2>&1 || true
grep -E "maximum resident|page faults|context switch" "$TMP/time.txt" \
    | tee -a "$RESULT_FILE"
log ""
log "===== 末轮累计计数（O2） ====="
tail -3 "$TMP/O2-${RUNS}.txt" | tee -a "$RESULT_FILE"
