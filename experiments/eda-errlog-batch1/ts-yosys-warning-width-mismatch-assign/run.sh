#!/usr/bin/env bash
# 复现「Yosys 位宽不匹配告警」+ 截断后果的 iverilog 仿真
set -u
cd "$(dirname "$0")"
mkdir -p logs

run_log() {
  local name="$1"; shift
  {
    echo "# command: $*"
    echo "# date: $(date +%FT%T%z)"
    echo "# host-toolchain: $(yosys -V 2>/dev/null | head -1) / $(iverilog -V 2>/dev/null | head -1)"
    echo "---"
    "$@"
    rc=$?
    echo "---"
    echo "# exit_code: $rc"
  } > "logs/$name.log" 2>&1
}

# 触发：隐式零扩展，yosys check 报 WIDTH 告警
run_log warn-width-mismatch yosys -Q -T -p "read_verilog src/width_bad.v; hierarchy -top width_bad; proc; opt; check"
# 修复：显式拼接零扩展
run_log fix-explicit-extend yosys -Q -T -p "read_verilog src/width_ok.v; hierarchy -top width_ok; proc; opt; check"
# 截断后果演示：8'h10 被截成 4'h0（iverilog 仿真）
( cd sim && iverilog -o trunc_tb.vvp trunc_tb.v && vvp trunc_tb.vv ) > logs/sim-truncation.log 2>&1

echo "== logs =="; wc -l logs/*.log
