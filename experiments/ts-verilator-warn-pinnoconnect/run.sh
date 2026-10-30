#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
status=0

run_warning() {
    local file="$1"
    local code="$2"
    local output
    local rc

    echo "=== $file: expect $code ==="
    echo "$ verilator --lint-only -Wall -Wwarn-PINNOCONNECT -Wno-DECLFILENAME --top-module top child.sv $file"
    output=$(verilator --lint-only -Wall -Wwarn-PINNOCONNECT -Wno-DECLFILENAME --top-module top child.sv "$file" 2>&1)
    rc=$?
    printf '%s\n' "$output"
    echo "# exit_code: $rc"
    if [ "$rc" -ne 0 ] && printf '%s\n' "$output" | grep -q "$code"; then
        echo "PASS: reproduced $code"
    else
        echo "FAIL: did not reproduce $code"
        status=1
    fi
    echo
}

run_fixed() {
    local file="$1"
    local output
    local rc

    echo "=== $file: expect clean lint ==="
    echo "$ verilator --lint-only -Wall -Wwarn-PINNOCONNECT -Wno-DECLFILENAME --top-module top child.sv $file"
    output=$(verilator --lint-only -Wall -Wwarn-PINNOCONNECT -Wno-DECLFILENAME --top-module top child.sv "$file" 2>&1)
    rc=$?
    printf '%s\n' "$output"
    echo "# exit_code: $rc"
    if [ "$rc" -eq 0 ]; then
        echo "PASS: $file lint clean"
    else
        echo "FAIL: $file still has lint diagnostics"
        status=1
    fi
    echo
}

run_warning bad_positional.sv PINNOCONNECT
run_warning boundary_empty.sv PINCONNECTEMPTY
run_warning boundary_missing.sv PINMISSING
run_fixed fixed_empty.sv
run_fixed fixed_connected.sv
exit "$status"
