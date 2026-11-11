#!/bin/bash
# 一键复现：三档 dump 深度 + dumpoff/dumpon/dumpall 时间窗
set -e

echo "# command: bash run.sh"
echo "# date: 2026-11-03"
echo "# host-toolchain: $(iverilog -V 2>/dev/null | head -1)"

rm -f simv_d0 simv_d1 simv_d2 simv_win depth0.vcd depth1.vcd depth2.vcd window.vcd

for d in 0 1 2; do
    echo "--- depth $d: iverilog + vvp ---"
    iverilog -g2012 -o simv_d$d tb_d$d.v counter.v
    vvp simv_d$d
done

echo "--- window: dumpoff/dumpon/dumpall ---"
iverilog -g2012 -o simv_win tb_window.v counter.v
vvp simv_win

echo
echo "=== 深度对照：scope 层数 / var 变量数 / 时间戳条数 ==="
for d in 0 1 2; do
    f="depth$d.vcd"
    printf "%s  scope=%s  var=%s  timestamps=%s  bytes=%s\n" "$f" \
        "$(grep -c '^\$scope' "$f")" \
        "$(grep -c '^\$var' "$f")" \
        "$(grep -c '^#' "$f")" \
        "$(wc -c < "$f" | tr -d ' ')"
done

echo
echo "=== depth0.vcd 头部：timescale/层次/变量声明 ==="
sed -n '1,22p' depth0.vcd

echo
echo "=== depth1.vcd 里的 scope（只应有 tb_d1 一层）==="
grep '^\$scope' depth1.vcd

echo
echo "=== depth0.vcd 里的 scope（应含 tb_d0/dut/u_inc 三层）==="
grep '^\$scope' depth0.vcd

echo
echo "=== depth0.vcd 值变化段前 14 行 ==="
awk '/^\$enddefinitions/{p=1;next} p{n++;if(n<=14)print} p&&n==14{exit}' depth0.vcd

echo
echo "=== window.vcd：100ns 暂停段（dumpoff 给所有信号写 x 基线）==="
awk '/^\$dumpoff/{p=1} p{print} p&&/^\$end/{exit}' window.vcd

echo
echo "=== window.vcd：200ns 恢复段（dumpon 快照 + 显式 dumpall 再补一帧）==="
awk '/^\$dumpon/{p=1} p{print} p&&/^\$dumpall/{f=1} f&&/^\$end/{exit}' window.vcd

echo
echo "=== window.vcd 时间戳序列（100000 与 200000 之间无任何时间戳）==="
grep '^#' window.vcd | tr '\n' ' '; echo
