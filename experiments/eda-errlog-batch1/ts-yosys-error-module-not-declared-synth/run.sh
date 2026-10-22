#!/usr/bin/env bash
# 复现「Yosys 模块未声明（综合阶段）」：只读顶层、漏读子模块
set -u
cd "$(dirname "$0")"
mkdir -p logs

run_log() {
  local name="$1"; shift
  {
    echo "# command: $*"
    echo "# date: $(date +%FT%T%z)"
    echo "# host-toolchain: $(yosys -V 2>/dev/null | head -1)"
    echo "---"
    "$@"
    rc=$?
    echo "---"
    echo "# exit_code: $rc"
  } > "logs/$name.log" 2>&1
}

# 触发：只读顶层不读子模块
run_log err-missing-submodule yosys -Q -T -p "read_verilog src/top_use_adder.v; synth -top top_use_adder"
# 修复：两个文件都读入
run_log fix-read-all yosys -Q -T -p "read_verilog src/top_use_adder.v src/sub_adder.v; synth -top top_use_adder; stat"

echo "== logs =="; wc -l logs/*.log
