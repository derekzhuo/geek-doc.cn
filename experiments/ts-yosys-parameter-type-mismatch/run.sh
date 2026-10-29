#!/usr/bin/env bash
set -euo pipefail

IMAGE="${YOSYS_IMAGE:-geek-eda:0.2}"

run_yosys() {
  docker run --rm -v "$PWD:/work" -w /work "$IMAGE" yosys "$@"
}

printf '%s\n' '=== toolchain ==='
run_yosys -V

printf '%s\n' '=== bad: string parameter ==='
bad_output="$(run_yosys -p 'read_verilog param_string_bad.v; hierarchy -top param_string_bad; proc; opt_clean; stat; dump param_string_bad')"
printf '%s\n' "$bad_output"
bad_status=$?
printf 'BAD_EXIT=%d\n' "$bad_status"

printf '%s\n' '=== fixed: numeric parameter and derived width ==='
fixed_output="$(run_yosys -p 'read_verilog param_fixed.v; hierarchy -top param_fixed; proc; opt_clean; stat; dump param_fixed')"
printf '%s\n' "$fixed_output"
fixed_status=$?
printf 'FIX_EXIT=%d\n' "$fixed_status"

printf '%s\n' '=== observed evidence ==='
printf 'BAD_EXIT=%d\n' "$bad_status"
printf 'FIX_EXIT=%d\n' "$fixed_status"
printf '%s\n' "$bad_output" | grep -F "Parameter \\WIDTH = 8'00111000"
printf '%s\n' "$bad_output" | grep -F 'wire width 56 output 1 \observed'
printf '%s\n' "$fixed_output" | grep -F 'Parameter \WIDTH = 8'
printf '%s\n' "$fixed_output" | grep -F 'wire width 8 output 1 \observed_mask'
printf '%s\n' "$fixed_output" | grep -F 'wire width 3 output 2 \observed_index'
printf '%s\n' 'PASS: string "8" silently became 56; numeric 8 produced widths 8 and 3'
