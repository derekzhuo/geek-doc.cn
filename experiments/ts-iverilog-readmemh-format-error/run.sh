#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
trap 'rm -f simv' EXIT

printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-30'
printf '%s\n' '# host-toolchain: macOS 26.5.2 x86_64 / Icarus Verilog 13.0 (stable)'

iverilog -g2012 -s tb -o simv tb.sv
compile_rc=$?
printf 'compile exit=%d\n' "$compile_rc"
if [ "$compile_rc" -ne 0 ]; then
  exit "$compile_rc"
fi

for name in bad-char bad-address fixed; do
  printf '\n=== %s ===\n' "$name"
  printf '$ vvp simv +MEM_FILE=%s.hex\n' "$name"
  vvp "simv" "+MEM_FILE=${name}.hex"
  run_rc=$?
  printf '%s exit=%d\n' "$name" "$run_rc"
done

if grep -q 'mem\[2\]=22' <(vvp simv +MEM_FILE=fixed.hex) && [ "$run_rc" -eq 0 ]; then
  printf '\nPASS: invalid character and out-of-range address diagnosed; fixed data loaded\n'
  exit 0
fi
printf '\nFAIL: fixed data verification did not pass\n'
exit 1
