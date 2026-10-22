#!/usr/bin/env bash
# 复现 Verilator %Warning-CASEINCOMPLETE 及补 default 修复
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

run_log warn-CASEINCOMPLETE verilator --lint-only -Wall src/case_bad.v
run_log fix-add-default verilator --lint-only -Wall src/case_ok.v

echo "== logs =="; wc -l logs/*.log
