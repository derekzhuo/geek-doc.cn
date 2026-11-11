#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")"

verilator --version
printf '\n== unnamed generate: GENUNNAMED expected ==\n'
printf '$ verilator --lint-only -Wall unnamed.sv\n'
if verilator --lint-only -Wall unnamed.sv 2>&1; then
    printf 'FAIL: unnamed generate unexpectedly passed\n'
    exit 1
else
    printf 'Expected failure reproduced: GENUNNAMED\n'
fi

printf '\n== named generate: clean lint expected ==\n'
printf '$ verilator --lint-only -Wall named.sv\n'
verilator --lint-only -Wall named.sv 2>&1
printf 'PASS: named generate has no warnings\n'
