#!/usr/bin/env bash
# 复现「Yosys 找不到顶层模块」：-top 名字不存在 / 空设计直接 synth / 修复
# 产物：logs/*.log（报错两份 + 修复一份）
set -u
cd "$(dirname "$0")"
mkdir -p logs
SRC=src/counter8.v

run_log() { # run_log <name> <cmd...>
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

# 触发①：synth -top 指定的名字在设计里不存在
run_log err1-no-such-top yosys -Q -T -p "read_verilog $SRC; synth -top top"
# 触发②：根本没读入任何文件就 synth
run_log err2-empty-design yosys -Q -T -p "synth -top counter8"
# 修复：-top 指向真实存在的模块
run_log fix-synth-pass yosys -Q -T -p "read_verilog $SRC; synth -top counter8; stat"

echo "== logs =="; wc -l logs/*.log
