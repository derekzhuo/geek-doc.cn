#!/usr/bin/env bash
set -u

verilator --version

default_output="$(verilator --lint-only -Wall needtimingopt_broken.sv 2>&1)"
default_status=$?
printf '%s\n' "$default_output"
printf 'default exit=%d\n' "$default_status"

timing_output="$(verilator --lint-only -Wall --timing needtimingopt_broken.sv 2>&1)"
timing_status=$?
if [[ -n "$timing_output" ]]; then
    printf '%s\n' "$timing_output"
else
    printf '%s\n' '--timing diagnostics: none'
fi
printf '%s\n' "--timing exit=$timing_status"

no_timing_output="$(verilator --lint-only -Wall --no-timing needtimingopt_broken.sv 2>&1)"
no_timing_status=$?
printf '%s\n' "$no_timing_output"
printf '%s\n' "--no-timing exit=$no_timing_status"

failed=0
if [[ "$default_status" -eq 0 ]] || ! grep -q '%Error-NEEDTIMINGOPT' <<< "$default_output"; then
    printf '%s\n' 'FAIL: default lint did not report NEEDTIMINGOPT with nonzero exit'
    failed=1
fi
if [[ "$timing_status" -ne 0 || -n "$timing_output" ]]; then
    printf '%s\n' 'FAIL: --timing lint did not pass cleanly'
    failed=1
fi
if [[ "$no_timing_status" -eq 0 ]] || ! grep -q '%Warning-STMTDLY' <<< "$no_timing_output"; then
    printf '%s\n' 'FAIL: --no-timing did not report STMTDLY with nonzero exit under -Wall'
    failed=1
fi
if [[ "$failed" -eq 0 ]]; then
    printf '%s\n' 'PASS: default NEEDTIMINGOPT; --timing clean; --no-timing STMTDLY and nonzero under -Wall'
fi
exit "$failed"
