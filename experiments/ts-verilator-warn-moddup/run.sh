#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-30'
printf '# host-toolchain: '
verilator --version

printf '%s\n' '=== broken: two definitions of pulse_dup ==='
printf '%s\n' '$ verilator --lint-only -Wall --top-module top -f broken.f'
verilator --lint-only -Wall --top-module top -f broken.f
broken_rc=$?
printf 'broken exit=%s\n' "$broken_rc"

printf '%s\n' '=== bbox-unsup: not a duplicate-module switch ==='
printf '%s\n' '$ verilator --lint-only -Wall --bbox-unsup --top-module top -f broken.f'
verilator --lint-only -Wall --bbox-unsup --top-module top -f broken.f
bbox_rc=$?
printf 'bbox-unsup exit=%s\n' "$bbox_rc"

printf '%s\n' '=== fixed: remove legacy_pulse.v from the file list ==='
printf '%s\n' '$ verilator --lint-only -Wall --top-module top -f fixed.f'
verilator --lint-only -Wall --top-module top -f fixed.f
fixed_rc=$?
printf 'fixed exit=%s\n' "$fixed_rc"

if [ "$broken_rc" -ne 0 ] && [ "$bbox_rc" -ne 0 ] && [ "$fixed_rc" -eq 0 ]; then
  printf '%s\n' 'PASS: MODDUP reproduced; fixed file list exits 0'
  exit 0
fi
printf '%s\n' 'FAIL: unexpected exit code combination'
exit 1
