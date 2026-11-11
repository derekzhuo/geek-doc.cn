#!/usr/bin/env bash
# vector / deque / list 基准编排：
#   -O2 与 -O0 各跑 7 次，按行标签对 ms 数值取中位；
#   单容器模式再跑 /usr/bin/time -l，取 RSS、缺页与上下文切换对照。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make clean >/dev/null
make >/dev/null

log "# vector/deque/list 遍历与插删基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $(clang++ --version | head -1)"
log "# flags: -std=c++17 -Wall -Wextra；O2/O0 各运行 ${RUNS} 次取中位"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for opt in O2 O0; do
    for i in $(seq 1 "$RUNS"); do
        "./bin/bench-${opt}" all > "$TMP/${opt}-${i}.txt"
    done
done

log "===== -O2 首次完整输出（含 sizeof 与堆占用记账） ====="
cat "$TMP/O2-1.txt" | tee -a "$RESULT_FILE"
log ""

# 含 ms 的耗时行：首个小数即测量值，按标签聚合 7 次取中位。
for opt in O2 O0; do
    log "===== -${opt} 耗时行 ${RUNS} 次中位 ====="
    labels=$(perl -ne 'print if /ms/ && !/^#/' "$TMP/${opt}-1.txt" | perl -pe 's/[0-9]+\.[0-9]+//')
    while IFS= read -r label; do
        [ -z "$label" ] && continue
        vals=()
        for i in $(seq 1 "$RUNS"); do
            v="$(perl -e '
                my $lbl = shift; my $file = shift; local $/;
                open my $fh, "<", $file or exit;
                for my $line (split /\n/, <$fh>) {
                    next unless $line =~ /ms/;
                    my $masked = $line; $masked =~ s/[0-9]+\.[0-9]+//;
                    next unless $masked eq $lbl;
                    if ($line =~ /([0-9]+\.[0-9]+)/) { print $1; last; }
                }' "$label" "$TMP/${opt}-${i}.txt")"
            vals+=("$v")
        done
        num="$(median "${vals[@]}")"
        log "$(printf '%s 中位=%s ms' "$(echo "$label" | sed 's/ *:.*//')" "$num")"
    done <<< "$labels"
    log ""
done

log "===== /usr/bin/time -l 单容器内存与调度证据（-O2） ====="
for m in vector deque list; do
    log "--- ${m} ---"
    /usr/bin/time -l "./bin/bench-O2" "$m" 2>&1 \
        | grep -Ei "resident|page reclaim|page fault|context switch" | tee -a "$RESULT_FILE"
    log ""
done
log "done"
