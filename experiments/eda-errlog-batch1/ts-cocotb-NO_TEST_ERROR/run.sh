#!/usr/bin/env bash
# 复现 cocotb「NO_TEST_ERROR / 0 tests collected」：
# 错 MODULE 名 → CRITICAL Failed to import module；正确 MODULE → 2 个测试 PASS
set -u
cd "$(dirname "$0")/lab"
mkdir -p ../logs
# 优先用本目录 .venv（python3 -m venv .venv && .venv/bin/pip install cocotb）
[ -x ../.venv/bin/cocotb-config ] && export PATH="$(cd ../.venv/bin && pwd):$PATH"

run_log() {
  local name="$1"; shift
  {
    echo "# command: $*"
    echo "# date: $(date +%FT%T%z)"
    echo "# host-toolchain: $(cocotb-config --version 2>/dev/null) / $(iverilog -V 2>/dev/null | head -1)"
    echo "---"
    "$@"
    rc=$?
    echo "---"
    echo "# exit_code: $rc"
  } > "../logs/$name.log" 2>&1
}

# 触发：MODULE 指向不存在的 Python testbench 模块
run_log err-wrong-MODULE make MODULE=nonexistent_tb
# 修复：MODULE 与文件名（去 .py）一致
run_log fix-correct-MODULE make

echo "== logs =="; wc -l ../logs/*.log
