# vcd2table.awk —— 把 counter.vcd 解码成「时间 信号值」对照表
# 本实验 VCD 的标识符：!=tb.count  "=clk  #=en  $=rst_n  %=dut.count
BEGIN {
    printf "%-10s %-6s %-6s %-4s %-10s %-10s\n", "time(ps)", "clk", "rst_n", "en", "tb.count", "dut.count"
    clk="x"; rst="x"; en="x"; tbc="x"; dutc="x"
}
/^#/ {
    t = substr($0, 2)
    # 上一时间戳结束后先输出一行聚合值（只在有变化的时间点输出）
    if (t != prev && NR > 1 && seen) {
        printf "%-10s %-6s %-6s %-4s %-10s %-10s\n", prev, clk, rst, en, tbc, dutc
    }
    prev = t
}
/^0"/ { clk="0"; seen=1 }
/^1"/ { clk="1"; seen=1 }
/^0\$/ { rst="0"; seen=1 }
/^1\$/ { rst="1"; seen=1 }
/^0#/ { en="0"; seen=1 }
/^1#/ { en="1"; seen=1 }
/^b[01xz]+ %/ { v=$0; sub(/^b/, "", v); sub(/ %$/, "", v); dutc=bin2dec(v); seen=1 }
/^bx %/ { dutc="x"; seen=1 }
/^b[01xz]+ !/ { v=$0; sub(/^b/, "", v); sub(/ !$/, "", v); tbc=bin2dec(v); seen=1 }
/^bx !/ { tbc="x"; seen=1 }
END {
    printf "%-10s %-6s %-6s %-4s %-10s %-10s\n", prev, clk, rst, en, tbc, dutc
}
function bin2dec(b,   i, n, d) {
    n = length(b); d = 0
    for (i = 1; i <= n; i++) d = d * 2 + substr(b, i, 1)
    return d
}
