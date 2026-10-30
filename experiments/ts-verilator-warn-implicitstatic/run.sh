#!/usr/bin/env bash
set -u

printf '$ verilator --version\n'
verilator --version

printf '\n$ verilator --lint-only -Wall implicitstatic_bad.sv\n'
set +e
verilator --lint-only -Wall implicitstatic_bad.sv
bad_rc=$?
set -e
printf '# bad_exit_code: %d\n' "$bad_rc"
if [ "$bad_rc" -eq 0 ]; then
  printf 'FAIL: expected IMPLICITSTATIC was not reported\n'
  exit 1
fi

printf '\n$ verilator --lint-only -Wall implicitstatic_fixed.sv\n'
verilator --lint-only -Wall implicitstatic_fixed.sv
printf '# fixed_exit_code: 0\n'
printf 'PASS: IMPLICITSTATIC reproduced; automatic fix is clean\n'
