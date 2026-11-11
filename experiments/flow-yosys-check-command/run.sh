#!/usr/bin/env bash
# 一条脚本跑完整条证据链：check 在 proc 前后的差异、-assert 门禁、修复复跑。
set -u

echo "=== STEP 0  工具版本 ==="
yosys -V
echo

echo "=== STEP A  check 放在 proc 之前（带错设计 alu_bad）==="
yosys -p 'read_verilog alu_bad.v; hierarchy -top alu_bad; check'
echo

echo "=== STEP B  proc 之后再 check（多驱动/位宽在此现形）==="
yosys -p 'read_verilog alu_bad.v; hierarchy -top alu_bad; proc; check'
echo

echo "=== STEP C  check -assert 当门禁：带错设计应被非零退出拦下 ==="
yosys gate-bad.ys
echo "gate-bad exit code = $?"
echo

echo "=== STEP D  修复版 alu：proc; check 应为 0 problems ==="
yosys -p 'read_verilog alu.v; hierarchy -top alu; proc; check'
echo

echo "=== STEP E  修复版过门禁脚本 gate.ys ==="
yosys gate.ys
echo "gate exit code = $?"
