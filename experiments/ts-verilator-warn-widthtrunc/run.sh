#!/usr/bin/env bash
set -u

set +e
echo '$ verilator --lint-only -Wall widthtrunc_broken.sv'
verilator --lint-only -Wall widthtrunc_broken.sv
broken_status=$?
echo "# broken_exit_code: ${broken_status}"

echo '$ verilator --lint-only -Wall widthtrunc_fixed.sv'
verilator --lint-only -Wall widthtrunc_fixed.sv
fixed_status=$?
echo "# fixed_exit_code: ${fixed_status}"
set -e

if [[ ${broken_status} -eq 0 ]]; then
    echo '# result: FAIL (broken case unexpectedly passed)'
    exit 1
fi
if [[ ${fixed_status} -ne 0 ]]; then
    echo '# result: FAIL (fixed case did not pass)'
    exit 1
fi

echo '# result: PASS (WIDTHTRUNC reproduced; explicit bit select passed)'
