#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-31'
printf '%s\n' '# host-toolchain: Icarus Verilog 13.0 / macOS'

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
unexpected=0

compile_should_fail() {
    label="$1"
    source_file="$2"
    printf '\n--- %s ---\n' "$label"
    if iverilog -g2012 -Wall -o "$workdir/$label.vvp" "$source_file"; then
        printf 'UNEXPECTED compile success: %s\n' "$source_file"
        unexpected=1
    else
        status=$?
        printf 'EXPECTED compile failure: %s (exit %d)\n' "$source_file" "$status"
    fi
}

compile_should_fail bad_if bad_if.v
compile_should_fail bad_assign bad_assign.v
compile_should_fail bad_initial_outside bad_initial_outside.v
compile_should_fail bad_parenthesis bad_parenthesis.v

printf '\n--- fixed compile and simulation ---\n'
if ! iverilog -g2012 -Wall -s tb -o "$workdir/fixed.vvp" scope_fixed.v tb_fixed.v; then
    printf 'FAIL: repaired sources did not compile\n'
    exit 1
fi
if ! vvp "$workdir/fixed.vvp"; then
    printf 'FAIL: repaired simulation did not pass\n'
    exit 1
fi

if [ "$unexpected" -ne 0 ]; then
    printf 'FAIL: an invalid source unexpectedly compiled\n'
    exit 1
fi
printf 'RESULT: four invalid sources rejected; repaired simulation passed\n'
