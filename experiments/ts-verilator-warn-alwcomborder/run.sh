#!/usr/bin/env bash
set -u

cd "$(dirname "$0")"

echo '$ verilator --version'
verilator --version

echo '$ verilator --lint-only -Wall alwcomborder_bad.sv'
if verilator --lint-only -Wall alwcomborder_bad.sv; then
    echo 'UNEXPECTED: bad source passed lint'
    exit 1
else
    status=$?
    echo "EXPECTED: bad source failed lint (exit=$status)"
fi

echo '$ verilator --lint-only -Wall alwcomborder_fixed.sv'
if verilator --lint-only -Wall alwcomborder_fixed.sv; then
    echo 'PASS: fixed source passed lint with no warnings'
else
    status=$?
    echo "FAIL: fixed source failed lint (exit=$status)"
    exit "$status"
fi
