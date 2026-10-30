#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

echo '$ iverilog -g2005 -o bad.vvp bad.v'
iverilog -g2005 -o bad.vvp bad.v
bad_status=$?
echo "bad compile exit code: $bad_status"

echo '$ iverilog -g2005 -o fixed.vvp fixed.v'
iverilog -g2005 -o fixed.vvp fixed.v
fixed_compile_status=$?

fixed_run_status=1
if [ "$fixed_compile_status" -eq 0 ]; then
  echo '$ vvp fixed.vvp'
  vvp fixed.vvp
  fixed_run_status=$?
fi

if [ "$bad_status" -ne 0 ] && [ "$fixed_compile_status" -eq 0 ] && [ "$fixed_run_status" -eq 0 ]; then
  echo 'PASS: bad.v failed to compile; fixed.v compiled and ran'
  exit 0
fi

echo 'FAIL: unexpected experiment result'
exit 1
