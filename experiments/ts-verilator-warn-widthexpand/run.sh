#!/usr/bin/env bash
set -u

verilator --version

broken_output="$(verilator --lint-only -Wall widthexpand_broken.sv 2>&1)"
broken_status=$?
printf '%s\n' "$broken_output"
printf 'broken exit=%d\n' "$broken_status"

fixed_output="$(verilator --lint-only -Wall widthexpand_fixed.sv 2>&1)"
fixed_status=$?
if [[ -n "$fixed_output" ]]; then
    printf '%s\n' "$fixed_output"
else
    printf 'fixed diagnostics: none\n'
fi
printf 'fixed exit=%d\n' "$fixed_status"

warning_count="$(grep -c '%Warning-WIDTHEXPAND' <<< "$broken_output")"
failed=0
if [[ "$broken_status" -eq 0 ]]; then
    printf 'FAIL: broken lint unexpectedly passed\n'
    failed=1
fi
if [[ "$warning_count" -ne 2 ]]; then
    printf 'FAIL: expected 2 WIDTHEXPAND warnings, got %s\n' "$warning_count"
    failed=1
fi
if [[ "$fixed_status" -ne 0 || -n "$fixed_output" ]]; then
    printf 'FAIL: fixed lint did not pass cleanly\n'
    failed=1
fi
if [[ "$failed" -eq 0 ]]; then
    printf 'PASS: broken reported unsigned and signed WIDTHEXPAND; fixed lint exited 0\n'
fi
exit "$failed"
