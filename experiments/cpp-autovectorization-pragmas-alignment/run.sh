#!/usr/bin/env bash
# 自动向量化基准编排：
#   1) 三档构建（-O2 / -O2 禁向量化 / -O2 -march=native）+ 逐组 -Rpass 报告；
#   2) 三档各跑 7 次，按组标签对 ns/pass 取中位；
#   3) 以禁向量化档为标量基线算加速比；
#   4) otool 摘录向量指令计数、G4 版本化标量序言、G8 对齐 load。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

echo '$ bash run.sh'
make clean >/dev/null
make all >/dev/null
make reports >/dev/null

log "# 自动向量化对照基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $(clang++ --version | head -1)"
log "# flags: -std=c++17 -Wall -Wextra；O2/scalar/native 三档各 ${RUNS} 次取中位"
log "# N=262144 元素，PASSES=200，时间单位 ns/pass"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for bin in O2 scalar native; do
    for i in $(seq 1 "$RUNS"); do
        "./bin/bench-${bin}" > "$TMP/${bin}-${i}.txt"
    done
done

log "===== bench-O2 首次完整输出（11 组 ns/pass 与 checksum） ====="
cat "$TMP/O2-1.txt" | tee -a "$RESULT_FILE"
log ""

# 按组标签聚合 7 次测量取中位，三档各一张表。
for bin in O2 scalar native; do
    log "===== -${bin} 档各组 ${RUNS} 次中位（ns/pass） ====="
    labels=$(perl -ne 'print if /ns\/pass/' "$TMP/${bin}-1.txt" | perl -pe 's/[0-9]+\.[0-9]+//')
    while IFS= read -r label; do
        [ -z "$label" ] && continue
        vals=()
        for i in $(seq 1 "$RUNS"); do
            v="$(perl -e '
                my $lbl = shift; my $file = shift; local $/;
                open my $fh, "<", $file or exit;
                for my $line (split /\n/, <$fh>) {
                    next unless $line =~ /ns\/pass/;
                    my $masked = $line; $masked =~ s/[0-9]+\.[0-9]+//;
                    next unless $masked eq $lbl;
                    if ($line =~ /([0-9]+\.[0-9]+)/) { print $1; last; }
                }' "$label" "$TMP/${bin}-${i}.txt")"
            vals+=("$v")
        done
        num="$(median "${vals[@]}")"
        log "$(printf '%-22s 中位=%s ns/pass' "$(echo "$label" | awk '{print $1}')" "$num")"
    done <<< "$labels"
    log ""
done

# 加速比：标量档中位 / O2 档中位，按 results.txt 的分节标题归位。
log "===== 向量化加速比（scalar 中位 / O2 中位，1.00x 即未受益） ====="
perl -ne '
    if (/===== -(\S+) 档/) { $sec = $1; next; }
    if (/^(\S+)\s+中位=([0-9.]+)/) { $m{$sec}{$1} = $2; }
    END {
        for my $k (sort keys %{$m{O2}}) {
            my ($o, $s) = ($m{O2}{$k}, $m{scalar}{$k});
            next unless defined $s && $o > 0;
            printf "%-22s O2=%12.4f  scalar=%12.4f  speedup=%.2fx\n",
                   $k, $o, $s, $s / $o;
        }
    }' "$RESULT_FILE" | tee -a "$RESULT_FILE"
log ""

# 编译器向量化报告：只留 remark 正文行，去掉源码与光标行。
log "===== -O2 逐组向量化报告（-Rpass 三兄弟原文摘录） ====="
for r in reports/O2-g*.txt; do
    g="$(basename "$r" .txt)"
    log "--- $g ---"
    grep 'remark:' "$r" | sed 's/ \[-Rpass[^]]*\]//' | tee -a "$RESULT_FILE" || true
done
log ""

log "===== native 档（-march=native）向量宽度变化摘录 ====="
grep -H 'remark:' reports/native-g1_axpy_restrict.txt reports/native-g2_isum.txt \
    | sed 's/ \[-Rpass[^]]*\]//' | tee -a "$RESULT_FILE" || true
log ""

log "===== -funroll-loops 下 G9 报告（对照 pragma unroll_count） ====="
grep 'remark:' reports/funroll-g9_unroll.txt | sed 's/ \[-Rpass[^]]*\]//' \
    | tee -a "$RESULT_FILE" || true
log ""

# 反汇编证据：按 nm 符号地址区间摘函数体。
disasm_range() {
    local sym="$1" start end
    start=$(nm bin/bench-O2 | sort | awk -v s="$sym" '$0 ~ s {print $1; exit}')
    end=$(nm bin/bench-O2 | sort | awk -v s="$sym" '{if (p) {print $1; exit} if ($0 ~ s) p=1}')
    otool -tvV bin/bench-O2 | awk -v lo="$start" -v hi="$end" '
        /^[0-9a-f]{16}[[:space:]]/ { addr = $1; f = (addr >= lo && addr < hi) }
        f { print }'
}

log "===== 反汇编：三档二进制的打包向量指令条数（SSE addpd/movupd 与 AVX vaddpd/vmovupd 等） ====="
for bin in O2 scalar native; do
    cnt="$(otool -tvV bin/bench-${bin} | grep -cE '\b(v?addpd|v?mulpd|v?subpd|v?movupd|v?movapd|vp?addq|vp?movsxdq)\b' || true)"
    log "bin/bench-${bin}: packed_vector_insn=${cnt}"
done
log ""

log "===== 反汇编：G4 裸指针版本的运行时别名检查与标量/向量双路径 ====="
disasm_range "g4_alias" | grep -E 'movsd|addsd|movupd|addpd|jae|jbe|jb |ja |leaq' | head -14 \
    | tee -a "$RESULT_FILE" || true
log ""

log "===== 反汇编：G1 restrict 版本向量主体（movupd/addpd，尾部才回退标量） ====="
disasm_range "g1_axpy" | grep -E 'movupd|addpd|mulpd|movsd|addsd' | head -12 \
    | tee -a "$RESULT_FILE" || true
log ""

log "===== 反汇编：G8 对齐承诺产生的对齐 load（movapd）对照错位版（movupd） ====="
log "--- g8_aligned ---"
disasm_range "g8_aligned" | grep -E 'movapd|movupd|v?addpd' | head -6 | tee -a "$RESULT_FILE" || true
log "--- g8_misaligned ---"
disasm_range "g8_misaligned" | grep -E 'movapd|movupd|v?addpd' | head -6 | tee -a "$RESULT_FILE" || true
log ""

# 平台边界探针：GCC 的 -fopt-info-vec 在 Apple clang 上不是合法参数。
log "===== 平台探针：Apple clang 对 GCC 风格 -fopt-info-vec 的诊断 ====="
clang++ -O2 -fopt-info-vec -std=c++17 -c src/g1_axpy_restrict.cpp -o "$TMP/fopt-probe.o" 2>&1 | tee -a "$RESULT_FILE" || true
log "done"
