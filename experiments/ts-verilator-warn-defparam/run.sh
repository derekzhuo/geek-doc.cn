#!/usr/bin/env bash
set -u

printf '$ verilator --version\n'
verilator --version

printf '\n$ verilator --lint-only -Wall --top-module defparam_bad width_adapter.sv defparam_bad.sv\n'
set +e
verilator --lint-only -Wall --top-module defparam_bad width_adapter.sv defparam_bad.sv
bad_rc=$?
set -e
printf '# bad_exit_code: %d\n' "$bad_rc"
if [ "$bad_rc" -eq 0 ]; then
  printf 'FAIL: expected DEFPARAM was not reported\n'
  exit 1
fi

printf '\n$ verilator --lint-only -Wall --top-module defparam_fixed width_adapter.sv defparam_fixed.sv\n'
verilator --lint-only -Wall --top-module defparam_fixed width_adapter.sv defparam_fixed.sv
printf '# fixed_exit_code: 0\n'
printf 'PASS: DEFPARAM reproduced; named parameter override is clean\n'
