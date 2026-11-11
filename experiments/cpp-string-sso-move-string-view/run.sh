#!/usr/bin/env bash
# std::string SSO / 移动 / string_view 基准编排：
#   -O2 与 -O0 各跑 7 次，按行标签对 ns 数值取中位；
#   附 nm/otool 证据固定 operator new 重载与 malloc 调用点。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make clean >/dev/null
make >/dev/null

log "# std::string SSO / 移动 / string_view 基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
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

# 含 ns/ 的耗时行：首个小数即测量值，按标签聚合 7 次取中位。
for opt in O2 O0; do
    log "===== -${opt} 耗时行 ${RUNS} 次中位 ====="
    labels=$(perl -ne 'print if /ns\/(次|轮)/ && !/^#/' "$TMP/${opt}-1.txt" | perl -pe 's/[0-9]+\.[0-9]+//')
    while IFS= read -r label; do
        [ -z "$label" ] && continue
        vals=()
        for i in $(seq 1 "$RUNS"); do
            v="$(perl -e '
                my $lbl = shift; my $file = shift; local $/;
                open my $fh, "<", $file or exit;
                for my $line (split /\n/, <$fh>) {
                    next unless $line =~ /ns\/(次|轮)/;
                    my $masked = $line; $masked =~ s/[0-9]+\.[0-9]+//;
                    next unless $masked eq $lbl;
                    if ($line =~ /([0-9]+\.[0-9]+)/) { print $1; last; }
                }' "$label" "$TMP/${opt}-${i}.txt")"
            vals+=("$v")
        done
        num="$(median "${vals[@]}")"
        log "$(printf '%s 中位=%s ns' "$(echo "$label" | sed 's/ *ns\/.*//')" "$num")"
    done <<< "$labels"
    log ""
done

log "===== 二进制证据：operator new 被本程序重载（T=本二进制定义） ====="
nm bin/bench-O2 | grep -E "(__Znwm|__Znam|align_val_t)" | head -8 | tee -a "$RESULT_FILE"
log ""
log "===== 反汇编证据：-O2 下 new 内联为 malloc/aligned_alloc 调用点 ====="
otool -tvV bin/bench-O2 | awk '/callq/{print $NF}' | grep -E "^_(malloc|aligned_alloc)$" | sort | uniq -c | tee -a "$RESULT_FILE" || true
log "done"
