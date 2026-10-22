#!/usr/bin/env bash
# 复现 Verilator「Cannot find file containing module」：漏列文件 / -I 路径错误 / 修复
set -u
cd "$(dirname "$0")"
mkdir -p logs

run_log() {
  local name="$1"; shift
  {
    echo "# command: $*"
    echo "# date: $(date +%FT%T%z)"
    echo "# host-toolchain: $(verilator --version 2>/dev/null)"
    echo "---"
    "$@"
    rc=$?
    echo "---"
    echo "# exit_code: $rc"
  } > "logs/$name.log" 2>&1
}

# 触发①：命令行漏列子模块文件
run_log err-missing-file verilator --lint-only src/top_use_adder.v
# 触发②：-I 路径错误
run_log err-bad-incdir verilator --lint-only -I/nonexistent_dir src/top_use_adder.v
# 修复：顶层与子模块一起给出
run_log fix-list-all verilator --lint-only src/top_use_adder.v src/sub_adder.v

echo "== logs =="; wc -l logs/*.log
