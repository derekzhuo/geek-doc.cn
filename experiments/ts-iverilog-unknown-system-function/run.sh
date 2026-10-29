#!/usr/bin/env bash
set -u

cd "$(dirname "$0")"

printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: %s\n\n' "$(iverilog -V 2>/dev/null | grep -m1 '^Icarus Verilog version')"

printf '=== broken: misspelled $fopen ===\n'
printf '$ iverilog -g2012 -s typo_tb -o typo.vvp broken_typo.v\n'
iverilog -g2012 -s typo_tb -o typo.vvp broken_typo.v 2>&1
typo_compile_rc=$?
printf 'typo compile exit=%d\n' "$typo_compile_rc"

typo_run_rc=1
if [ "$typo_compile_rc" -eq 0 ]; then
    printf '$ vvp typo.vvp\n'
    vvp typo.vvp 2>&1
    typo_run_rc=$?
fi
printf 'typo simulation exit=%d\n\n' "$typo_run_rc"

printf '=== fixed: corrected $fopen ===\n'
printf '$ iverilog -g2012 -s fixed_tb -o fixed.vvp fixed_typo.v\n'
iverilog -g2012 -s fixed_tb -o fixed.vvp fixed_typo.v 2>&1
fixed_compile_rc=$?
printf 'fixed compile exit=%d\n' "$fixed_compile_rc"

fixed_run_rc=1
if [ "$fixed_compile_rc" -eq 0 ]; then
    printf '$ vvp fixed.vvp\n'
    vvp fixed.vvp 2>&1
    fixed_run_rc=$?
fi
printf 'fixed simulation exit=%d\n\n' "$fixed_run_rc"

rm -f typo.vvp fixed.vvp

if [ "$typo_compile_rc" -ne 0 ] || [ "$typo_run_rc" -eq 0 ]; then
    printf 'FAIL: misspelled system function did not fail at simulation startup as expected\n'
    exit 1
fi
if [ "$fixed_compile_rc" -ne 0 ] || [ "$fixed_run_rc" -ne 0 ]; then
    printf 'FAIL: corrected source did not compile and run cleanly\n'
    exit 1
fi

printf 'PASS: unknown system function reproduced; typo fix compiled and ran\n'
