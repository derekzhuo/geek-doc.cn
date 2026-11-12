#!/bin/sh
set -u

printf '%s\n' '# command: docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 make run'
printf '%s\n' '# date: 2026-10-30'
printf '# host-toolchain: geek-eda:0.2 / '
verilator --version

printf '\n== broken ==\n'
verilator --lint-only -Wall unsigned_broken.sv >broken.log 2>&1
broken_rc=$?
cat broken.log
printf 'broken exit=%s\n' "$broken_rc"

printf '\n== fixed ==\n'
verilator --lint-only -Wall unsigned_fixed.sv >fixed.log 2>&1
fixed_rc=$?
if [ -s fixed.log ]; then
    cat fixed.log
else
    printf '%s\n' 'fixed diagnostics: none'
fi
printf 'fixed exit=%s\n' "$fixed_rc"

if [ "$broken_rc" -ne 0 ] &&
   grep -q '%Warning-UNSIGNED' broken.log &&
   [ "$fixed_rc" -eq 0 ] &&
   [ ! -s fixed.log ]; then
    printf '%s\n' 'PASS: mixed-sign comparison reported UNSIGNED; fixed lint exited 0'
    exit 0
fi

printf '%s\n' 'FAIL: expected broken UNSIGNED and clean fixed lint'
exit 1
