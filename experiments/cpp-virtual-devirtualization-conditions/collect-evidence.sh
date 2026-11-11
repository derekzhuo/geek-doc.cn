#!/usr/bin/env bash
# 反汇编证据采集：按 nm 给出的符号地址区间统计每个 run_* 函数内的间接调用数。
# 不用符号标签做 sed 边界——LTO 下 ICF 会把同构函数合并到同一地址、只留一个标签，
# 按标签截取会把别名函数误判成 0。地址区间对三档构建都成立。
# macOS 自带 BSD awk 无 strtonum，地址解析统一走 perl。
set -euo pipefail
cd "$(dirname "$0")"

SYMS="__Z10run_directl __Z13run_heap_openl __Z14run_heap_finall __Z17run_visible_locall __Z12run_cross_tul"

count_indirect() {
    local bin="$1"
    nm "$bin" | awk -v s="$SYMS" '
        BEGIN { n = split(s, want, " ") }
        { for (i = 1; i <= n; i++) if ($3 == want[i]) print $1, $3 }
    ' | sort > /tmp/cv-syms.txt
    otool -tvV "$bin" > /tmp/cv-disasm.txt
    perl -e '
        my ($symf, $disf, $tag) = @ARGV;
        my @syms;
        open my $sf, "<", $symf or die $!;
        while (<$sf>) { push @syms, [hex((split)[0]), (split)[1]]; }
        close $sf;
        my @cnt = (0) x @syms;
        open my $df, "<", $disf or die $!;
        while (<$df>) {
            next unless /^([0-9a-f]{16})\t/;
            my $cur = hex($1);
            my $idx = -1;
            for my $i (0 .. $#syms) { $idx = $i if $cur >= $syms[$i][0]; }
            $cnt[$idx]++ if $idx >= 0 && /callq\s+\*/;
        }
        close $df;
        for my $i (0 .. $#syms) {
            printf "%-12s %-24s indirect_callq=%d\n", $tag, $syms[$i][1], $cnt[$i];
        }
    ' /tmp/cv-syms.txt /tmp/cv-disasm.txt "$(basename "$bin")"
}

{
echo "## 五形态去虚化证据（Apple clang 21.0.0，-O2，100M 次/形态）"
echo "## 间接调用按符号地址区间统计（规避 LTO ICF 标签合并）"
for bin in bin/bench-none bin/bench-lto bin/bench-pgo; do
    echo "===== $bin ====="
    count_indirect "$bin"
    echo ""
done

echo "===== none 版 heap_open 热循环（间接调用 callq *0x10(%rcx) 每轮一次） ====="
otool -tvV bin/bench-none | awk '/__Z13run_heap_openl:/{f=1} f{print} f&&/retq/{exit}' | grep -E "callq|jne|jmp" | head -8
echo ""
echo "===== pgo 版 heap_open 热循环（守卫比较 + 函数体内联，jne 走冷兜底） ====="
otool -tvV bin/bench-pgo | awk '/__Z13run_heap_openl:/{f=1} f{print} f&&/retq/{exit}' | grep -E "leaq.*step|cmpq|jne|imulq|addq|callq" | head -10
} | tee evidence.log

rm -f /tmp/cv-syms.txt /tmp/cv-disasm.txt
