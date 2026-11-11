#!/usr/bin/env bash
# 四种输入解析路径（scanf / cin 默认 / cin 关同步 / 自定义 fread 快读）
# 在同一份 200 万行整数数据上的吞吐基准编排：
#   1. 生成 data.txt，O2/O0 双档编译；
#   2. 每组跨 7 个独立进程各跑一轮，按 ms 取中位（单进程单轮，流状态互不污染）；
#   3. 校验所有组所有轮次 checksum 一致；
#   4. O2 各组再用 /usr/bin/time -l 采驻留内存、次缺页与上下文切换。
set -euo pipefail
cd "$(dirname "$0")"

RESULT_FILE="results.txt"
PARSER_GROUPS=(scanf cin-default cin-fast custom)
RUNS="${RUNS:-7}"

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

make clean >/dev/null
make >/dev/null

log "# 输入解析四路径吞吐基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $(clang++ --version | head -1)"
log "# flags: -std=c++17 -Wall -Wextra；O2/O0 双档，每组 ${RUNS} 个独立进程取中位"
log ""

bin/bench-O2 gen | tee -a "$RESULT_FILE"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for opt in O2 O0; do
    log "===== -${opt} 四组各 ${RUNS} 轮原始输出 ====="
    for g in "${PARSER_GROUPS[@]}"; do
        for i in $(seq 1 "$RUNS"); do
            "./bin/bench-${opt}" "$g" | tee -a "$RESULT_FILE"
            "./bin/bench-${opt}" "$g" > "$TMP/${opt}-${g}-${i}.txt"
        done
    done
    log ""
    log "===== -${opt} 跨进程中位汇总 ====="
    for g in "${PARSER_GROUPS[@]}"; do
        vals=()
        for i in $(seq 1 "$RUNS"); do
            v="$(perl -ne 'print $1 if / ms=([0-9.]+)/' "$TMP/${opt}-${g}-${i}.txt")"
            vals+=("$v")
        done
        med="$(median "${vals[@]}")"
        sample="$(head -1 "$TMP/${opt}-${g}-1.txt")"
        n="$(perl -ne 'print $1 if /N=(\d+)/' <<<"$sample")"
        bytes="$(perl -ne 'print $1 if /bytes=(\d+)/' <<<"$sample")"
        cksum="$(perl -ne 'print $1 if /checksum=(-?\d+)/' <<<"$sample")"
        mlines="$(perl -e "printf '%.3f', ($n/1e6)/($med/1000)")"
        mbps="$(perl -e "printf '%.3f', ($bytes/1e6)/($med/1000)")"
        log "group=$g median_ms=$med throughput=$mlines Mlines/s $mbps MB/s checksum=$cksum"
    done
    log ""
done

log "===== checksum 一致性核验（去重后应只剩 1 个值） ====="
perl -ne 'print "$1\n" if /checksum=(-?\d+)/' "$TMP"/O2-*.txt | sort -u | tee -a "$RESULT_FILE"
log ""

log "===== /usr/bin/time -l 系统侧证据（仅 -O2，每组一次） ====="
for g in "${PARSER_GROUPS[@]}"; do
    log "--- time -l ${g} ---"
    /usr/bin/time -l "./bin/bench-O2" "$g" 2>&1 \
        | grep -E '(group=|maximum resident set size|page reclaims|voluntary context switches|involuntary context switches)' \
        | tee -a "$RESULT_FILE"
done
log "done"
