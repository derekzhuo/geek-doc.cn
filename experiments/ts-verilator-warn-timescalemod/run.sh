#!/usr/bin/env bash
set -u

rm -rf build
mkdir -p build
failed=0

printf '%s\n' '=== broken lint: one module has no timescale ==='
verilator --lint-only -Wall -Wwarn-TIMESCALEMOD --timing \
    --top-module timescalemod_top \
    broken/timescalemod_leaf.sv broken/timescalemod_top.sv \
    >build/broken-lint.log 2>&1
broken_lint_rc=$?
cat build/broken-lint.log
printf 'broken lint exit=%d\n\n' "$broken_lint_rc"
if [ "$broken_lint_rc" -ne 1 ] || ! grep -q 'TIMESCALEMOD' build/broken-lint.log; then
    failed=1
fi

printf '%s\n' '=== fixed lint: explicit 1ns/1ps in both modules ==='
verilator --lint-only -Wall -Wwarn-TIMESCALEMOD --timing \
    --top-module timescalemod_top \
    fixed/timescalemod_top.sv fixed/timescalemod_leaf.sv \
    >build/fixed-lint.log 2>&1
fixed_lint_rc=$?
cat build/fixed-lint.log
printf 'fixed lint exit=%d\n\n' "$fixed_lint_rc"
if [ "$fixed_lint_rc" -ne 0 ] || grep -q 'TIMESCALEMOD' build/fixed-lint.log; then
    failed=1
fi

printf '%s\n' '=== broken simulation: default 1ns happens to pass ==='
verilator --binary -Wall -Wwarn-TIMESCALEMOD --timing -Wno-fatal \
    --top-module timescalemod_top --Mdir build/broken-obj -o sim_broken \
    broken/timescalemod_leaf.sv broken/timescalemod_top.sv \
    >build/broken-build.log 2>&1
broken_build_rc=$?
cat build/broken-build.log
if [ "$broken_build_rc" -eq 0 ]; then
    ./build/broken-obj/sim_broken >build/broken-sim.log 2>&1
    broken_sim_rc=$?
else
    broken_sim_rc=125
fi
cat build/broken-sim.log 2>/dev/null || true
printf 'broken build exit=%d\nbroken simulation exit=%d\n\n' "$broken_build_rc" "$broken_sim_rc"
if [ "$broken_sim_rc" -ne 0 ] || ! grep -q 'PASS: pulse stayed low' build/broken-sim.log; then
    failed=1
fi

printf '%s\n' '=== fixed simulation: explicit 1ns preserves the checks ==='
verilator --binary -Wall --timing --top-module timescalemod_top \
    --Mdir build/fixed-obj -o sim_fixed \
    fixed/timescalemod_top.sv fixed/timescalemod_leaf.sv \
    >build/fixed-build.log 2>&1
fixed_build_rc=$?
cat build/fixed-build.log
if [ "$fixed_build_rc" -eq 0 ]; then
    ./build/fixed-obj/sim_fixed >build/fixed-sim.log 2>&1
    fixed_sim_rc=$?
else
    fixed_sim_rc=125
fi
cat build/fixed-sim.log 2>/dev/null || true
printf 'fixed build exit=%d\nfixed simulation exit=%d\n\n' "$fixed_build_rc" "$fixed_sim_rc"
if [ "$fixed_sim_rc" -ne 0 ] || ! grep -q 'PASS: pulse stayed low' build/fixed-sim.log; then
    failed=1
fi

printf '%s\n' '=== wrong-unit simulation: forcing the whole design to 1ps fails ==='
verilator --binary -Wall --timing --timescale-override 1ps/1ps \
    --top-module timescalemod_top --Mdir build/wrong-obj -o sim_wrong \
    fixed/timescalemod_top.sv fixed/timescalemod_leaf.sv \
    >build/wrong-build.log 2>&1
wrong_build_rc=$?
cat build/wrong-build.log
if [ "$wrong_build_rc" -eq 0 ]; then
    ./build/wrong-obj/sim_wrong >build/wrong-sim.log 2>&1
    wrong_sim_rc=$?
else
    wrong_sim_rc=125
fi
cat build/wrong-sim.log 2>/dev/null || true
printf 'wrong-unit build exit=%d\nwrong-unit simulation exit=%d\n\n' "$wrong_build_rc" "$wrong_sim_rc"
if [ "$wrong_sim_rc" -eq 0 ] || ! grep -q 'FAIL: pulse changed before 1ns' build/wrong-sim.log; then
    failed=1
fi

if [ "$failed" -eq 0 ]; then
    printf '%s\n' 'PASS: TIMESCALEMOD reproduced; explicit units fixed lint; forced 1ps failed simulation'
else
    printf '%s\n' 'FAIL: one or more experiment checks did not match expectations'
fi
exit "$failed"
