#!/usr/bin/env bash
set -uo pipefail

verilator --version
printf '\n== reproduce: last byte is not LF ==\n'
printf '$ verilator --lint-only -Wall eofnewline.sv\n'
verilator --lint-only -Wall eofnewline.sv 2>&1
bad_rc=$?
printf 'reproduce exit code: %s\n' "$bad_rc"
if [ "$bad_rc" -eq 0 ]; then
  printf 'FAIL: expected EOFNEWLINE, but lint passed\n'
  exit 1
fi

printf '\n== fix: append one LF, then rerun ==\n'
printf '$ verilator --lint-only -Wall eofnewline_fixed.sv\n'
verilator --lint-only -Wall eofnewline_fixed.sv 2>&1
fixed_rc=$?
printf 'fixed exit code: %s\n' "$fixed_rc"
if [ "$fixed_rc" -ne 0 ]; then
  printf 'FAIL: fixed source did not pass lint\n'
  exit "$fixed_rc"
fi
printf 'PASS: EOFNEWLINE disappeared after adding the final newline\n'
