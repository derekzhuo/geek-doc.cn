#!/usr/bin/env bash
set -u

printf '%s\n' '# command: verilator --lint-only -Wall <assignment/port bad and fixed sources>'
printf '%s\n' '# date: 2026-10-31'
printf '%s\n' '# host-toolchain: Docker geek-eda:0.2 / Verilator 5.020'

failed=0

run_case() {
  local expect="$1"
  shift
  local output
  local rc

  printf '\n$ verilator --lint-only -Wall %s\n' "$*"
  output=$(verilator --lint-only -Wall "$@" 2>&1)
  rc=$?
  printf '%s\n' "$output"
  printf 'exit_code: %s\n' "$rc"

  if [[ "$expect" == "warn" ]]; then
    if [[ $rc -eq 0 ]] || ! grep -q 'Warning-WIDTHCONCAT' <<<"$output"; then
      printf 'FAIL: expected WIDTHCONCAT and a nonzero exit for %s\n' "$*"
      failed=1
    fi
  else
    if [[ $rc -ne 0 ]] || grep -q '%Warning' <<<"$output"; then
      printf 'FAIL: expected clean lint for %s\n' "$*"
      failed=1
    fi
  fi
}

run_case warn widthconcat_assign_bad.sv
run_case warn widthconcat_port_bad.sv sink_64.sv
run_case clean widthconcat_assign_fixed.sv
run_case clean widthconcat_port_fixed.sv sink_64.sv

if [[ $failed -eq 0 ]]; then
  printf 'PASS: assignment and port cases warn; explicit width and intermediate signal are clean\n'
fi
exit "$failed"
