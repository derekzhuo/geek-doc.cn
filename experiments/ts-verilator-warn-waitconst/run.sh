#!/usr/bin/env bash
set -u

cd "$(dirname "$0")"

echo "experiment: ts-verilator-warn-waitconst"
echo "tool: $(verilator --version)"
echo "date: 2026-10-31"

run_lint() {
  local source_file=$1
  local output_file=$2
  echo "$ verilator --lint-only --timing -Wall $source_file"
  verilator --lint-only --timing -Wall "$source_file" >"$output_file" 2>&1
  local status=$?
  cat "$output_file"
  return "$status"
}

true_output=$(mktemp)
false_output=$(mktemp)
fixed_output=$(mktemp)
trap 'rm -f "$true_output" "$false_output" "$fixed_output"' EXIT

run_lint waitconst_bad.sv "$true_output"
true_status=$?
echo "constant_true_exit_code: $true_status"

run_lint waitconst_false.sv "$false_output"
false_status=$?
echo "constant_false_exit_code: $false_status"

run_lint waitconst_fixed.sv "$fixed_output"
fixed_status=$?
echo "fixed_exit_code: $fixed_status"

true_count=$(grep -c 'Warning-WAITCONST' "$true_output" || true)
false_count=$(grep -c 'Warning-WAITCONST' "$false_output" || true)
if [ "$true_status" -ne 0 ] && [ "$false_status" -eq 0 ] && [ "$fixed_status" -eq 0 ] && [ "$true_count" -eq 1 ] && [ "$false_count" -eq 0 ]; then
  echo "PASS: constant true warns; constant false is silent; event conditions are clean"
else
  echo "FAIL: true=$true_status false=$false_status fixed=$fixed_status counts=$true_count/$false_count"
  exit 1
fi
