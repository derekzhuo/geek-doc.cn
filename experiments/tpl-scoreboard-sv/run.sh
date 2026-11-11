#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

BUILD=".tb_scoreboard.vvp"
trap 'rm -f "$BUILD"' EXIT

echo '# command: bash run.sh'
echo '# date: 2026-10-31'
echo '# host-toolchain: Icarus Verilog 13.0 (stable) (v13_0)'

iverilog -g2012 -s tb_scoreboard -o "$BUILD" scoreboard_dut.sv tb_scoreboard.sv || exit 1

echo '=== PASS CASE ==='
vvp "$BUILD"
pass_rc=$?
echo "PASS_CASE_EXIT=$pass_rc"

echo '=== INJECTED MISMATCH CASE ==='
vvp "$BUILD" +INJECT_MISMATCH
mismatch_rc=$?
echo "MISMATCH_CASE_EXIT=$mismatch_rc"

if [ "$pass_rc" -eq 0 ] && [ "$mismatch_rc" -ne 0 ]; then
    echo 'RUN_SH_RESULT=PASS (normal case exited 0; injected mismatch was rejected)'
    exit 0
fi

echo 'RUN_SH_RESULT=FAIL (normal case must exit 0 and mismatch case must be nonzero)'
exit 1
