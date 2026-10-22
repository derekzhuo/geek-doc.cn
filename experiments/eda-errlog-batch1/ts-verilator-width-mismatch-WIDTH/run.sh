#!/usr/bin/env bash
# 复现 Verilator %Warning-WIDTH 及显式扩展修复
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

run_log warn-WIDTH verilator --lint-only -Wall src/vwidth_bad.v
run_log fix-zero-warning verilator --lint-only -Wall src/vwidth_ok.v

echo "== logs =="; wc -l logs/*.log
