#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"

verilator --version

echo '--- reproduce: ascending declaration [0:3] ---'
echo '$ verilator --lint-only -Wall ascrange_bad.sv'
bad_output=$(verilator --lint-only -Wall ascrange_bad.sv 2>&1)
bad_status=$?
printf '%s\n' "$bad_output"
echo "bad exit code: $bad_status"
if [ "$bad_status" -eq 0 ]; then
    echo 'FAIL: the bad example unexpectedly passed lint'
    exit 1
fi
if ! printf '%s\n' "$bad_output" | grep -q 'ASCRANGE'; then
    echo 'FAIL: expected ASCRANGE was not emitted'
    exit 1
fi

echo '--- fix: descending declaration [3:0] ---'
echo '$ verilator --lint-only -Wall ascrange_fixed.sv'
fixed_output=$(verilator --lint-only -Wall ascrange_fixed.sv 2>&1)
fixed_status=$?
printf '%s\n' "$fixed_output"
echo "fixed exit code: $fixed_status"
if [ "$fixed_status" -eq 0 ]; then
    echo 'PASS: descending declaration clears ASCRANGE; lint completed cleanly'
else
    echo 'FAIL: fixed example did not pass lint'
    exit 1
fi
