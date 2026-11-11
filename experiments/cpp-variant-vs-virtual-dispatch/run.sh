#!/usr/bin/env bash
# variant+visit 与虚函数多态基准编排：
#   -O2 与 -O0 各跑 7 次，按行标签对 ns/次 数值取中位；
#   附 nm/otool 证据固定 vtable 符号、visit 跳转表与虚调用间接 call。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make clean >/dev/null
make >/dev/null

log "# std::variant+visit vs 虚函数多态基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $(clang++ --version | head -1)"
log "# flags: -std=c++17 -Wall -Wextra；O2/O0 各运行 ${RUNS} 次取中位"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for opt in O2 O0; do
    for i in $(seq 1 "$RUNS"); do
        "./bin/bench-${opt}" "$opt" > "$TMP/${opt}-${i}.txt"
    done
done

log "===== -O2 首次完整输出（sizeof / 分配计数 / 六格耗时） ====="
cat "$TMP/O2-1.txt" | tee -a "$RESULT_FILE"
log ""

# 含 ns/次 的耗时行：首个小数即测量值，按标签聚合 7 次取中位。
for opt in O2 O0; do
    log "===== -${opt} 耗时行 ${RUNS} 次中位 ====="
    labels=$(perl -ne 'print if /ns\/次/ && !/^#/' "$TMP/${opt}-1.txt" | perl -pe 's/[0-9]+\.[0-9]+//')
    while IFS= read -r label; do
        [ -z "$label" ] && continue
        vals=()
        for i in $(seq 1 "$RUNS"); do
            v="$(perl -e '
                my $lbl = shift; my $file = shift; local $/;
                open my $fh, "<", $file or exit;
                for my $line (split /\n/, <$fh>) {
                    next unless $line =~ /ns\/次/;
                    my $masked = $line; $masked =~ s/[0-9]+\.[0-9]+//;
                    next unless $masked eq $lbl;
                    if ($line =~ /([0-9]+\.[0-9]+)/) { print $1; last; }
                }' "$label" "$TMP/${opt}-${i}.txt")"
            vals+=("$v")
        done
        num="$(median "${vals[@]}")"
        log "$(printf '%s 中位=%s ns/次' "$(echo "$label" | sed 's/ *ns\/次.*//')" "$num")"
    done <<< "$labels"
    log ""
done

log "===== 二进制证据：虚表与类型信息符号（仅虚多态实现需要） ====="
nm bin/bench-O2 | grep -E "__ZTV[0-9]|__ZTI[0-9]" | head -8 | tee -a "$RESULT_FILE" || true
log ""

# 按 nm 给出的符号地址区间提取反汇编（otool 对部分静态函数不打标签，地址区间最稳）。
disasm_range() {
    local sym="$1" start end
    start=$(nm bin/bench-O2 | sort | awk -v s="$sym" '$0 ~ s {print $1; exit}')
    end=$(nm bin/bench-O2 | sort | awk -v s="$sym" '{if (p) {print $1; exit} if ($0 ~ s) p=1}')
    otool -tvV bin/bench-O2 | awk -v lo="$start" -v hi="$end" '
        /^[0-9a-f]{16}[[:space:]]/ { addr = $1; f = (addr >= lo && addr < hi) }
        f { print }'
}

log "===== 反汇编证据：虚函数 runner 热循环里的间接 callq（vtable 槽位） ====="
disasm_range "run_virtual_mixed" | grep -E "callq|jmp" | head -10 | tee -a "$RESULT_FILE" || true
log ""
log "===== 反汇编证据：visit runner 热循环里的分派（按 discriminant 索引的函数表） ====="
disasm_range "run_visit_mixed" | grep -E "callq|jmp" | head -14 | tee -a "$RESULT_FILE" || true
log ""
log "===== 反汇编证据：get_if runner 热循环里零 call，索引跳转表加内联算术 ====="
disasm_range "run_manual_mixed" | grep -E "callq|jmp" | head -14 | tee -a "$RESULT_FILE" || true
log "done"
