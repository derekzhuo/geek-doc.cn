#!/usr/bin/env bash
# Sanitizer 开销基准编排（兼容 macOS 自带 Bash 3.2，不使用关联数组）：
#   五种构建各跑 7 个独立进程，进程内 chrono 计时、进程外 /usr/bin/time -l 采 RSS，
#   取中位并计算相对裸档倍数；随后实跑 TSan 数据竞争（含修复对照）与 UBSan 检测演示。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"
VARIANTS="plain ubsan asan aubsan tsan"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

log "# Sanitizer 运行时开销基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $(clang++ --version | head -1)"
log "# flags: -O2 -g -std=c++17，五变体各 ${RUNS} 个独立进程取中位，RSS 来自 /usr/bin/time -l"
log ""

make clean >/dev/null
make all >/dev/null

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for v in $VARIANTS; do
    for i in $(seq 1 "$RUNS"); do
        /usr/bin/time -l "./bin/bench-${v}" >"$TMP/${v}-${i}.out" 2>"$TMP/${v}-${i}.err"
        grep '^elapsed_ms=' "$TMP/${v}-${i}.out" | sed "s/^/sample ${v} #${i} /" >> "$RESULT_FILE"
    done
done
log ""

: > "$TMP/med.tsv"
for v in $VARIANTS; do
    ms_vals="$(grep -h '^elapsed_ms=' "$TMP"/${v}-*.out | sed 's/elapsed_ms=\([0-9.]*\).*/\1/')"
    rss_vals="$(grep -h 'maximum resident set size' "$TMP"/${v}-*.err | awk '{print $1}')"
    cs="$(grep -h '^elapsed_ms=' "$TMP"/${v}-1.out | sed 's/.*checksum=//')"
    echo "$v	$(median $ms_vals)	$(median $rss_vals)	$cs" >> "$TMP/med.tsv"
done

plain_ms="$(awk -F'	' '$1=="plain"{print $2}' "$TMP/med.tsv")"
plain_rss="$(awk -F'	' '$1=="plain"{print $3}' "$TMP/med.tsv")"
log "$(printf '%-8s %14s %10s %12s %12s %s' variant median_ms cpu_x rss_KiB mem_x checksum)"
while IFS='	' read -r v ms rss cs; do
    cpu_x="$(perl -e 'printf "%.2f", $ARGV[0]/$ARGV[1]' "$ms" "$plain_ms")"
    mem_x="$(perl -e 'printf "%.2f", $ARGV[0]/$ARGV[1]' "$rss" "$plain_rss")"
    rss_kib="$(perl -e 'printf "%.0f", $ARGV[0]/1024' "$rss")"
    log "$(printf '%-8s %14s %10s %12s %12s %s' "$v" "$ms" "$cpu_x" "$rss_kib" "$mem_x" "$cs")"
done < "$TMP/med.tsv"

log ""
log "== TSan 数据竞争实跑（未同步版本，预期必报） =="
./bin/race >"$TMP/race.out" 2>"$TMP/race.err" || true
cat "$TMP/race.out" | tee -a "$RESULT_FILE"
head -32 "$TMP/race.err" | tee -a "$RESULT_FILE"
race_warn="$(grep -c 'WARNING: ThreadSanitizer: data race' "$TMP/race.err" || true)"
log "racy build data-race warnings: ${race_warn}"

log ""
log "== TSan 修复对照（atomic 版本，预期零报告） =="
./bin/race-fixed >"$TMP/fixed.out" 2>"$TMP/fixed.err" || true
cat "$TMP/fixed.out" | tee -a "$RESULT_FILE"
fixed_warn="$(grep -c 'WARNING: ThreadSanitizer' "$TMP/fixed.err" || true)"
log "fixed build ThreadSanitizer warnings: ${fixed_warn}"

log ""
log "== UBSan 检测能力演示（有符号溢出 + 非法移位） =="
./bin/ub-demo >"$TMP/ub.out" 2>"$TMP/ub.err" || true
cat "$TMP/ub.out" | tee -a "$RESULT_FILE"
head -16 "$TMP/ub.err" | tee -a "$RESULT_FILE"

log ""
log "done"
