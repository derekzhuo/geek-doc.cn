#!/usr/bin/env bash
set -u

printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-30'
printf '# host-toolchain: Docker geek-eda:0.2 / '
verilator --version

status=0

run_case() {
    local name="$1"
    local file="$2"
    local language="$3"
    local expected="$4"
    local rc

    printf '\n=== %s ===\n' "$name"
    printf '$ verilator --lint-only -Wall --language %s %s\n' "$language" "$file"
    verilator --lint-only -Wall --language "$language" "$file"
    rc=$?
    printf '%s exit=%s\n' "$name" "$rc"

    if [ "$expected" = nonzero ] && [ "$rc" -eq 0 ]; then
        printf 'FAIL: %s should fail\n' "$name"
        status=1
    elif [ "$expected" = zero ] && [ "$rc" -ne 0 ]; then
        printf 'FAIL: %s should pass\n' "$name"
        status=1
    fi
}

run_case broken broken.v 1364-2005 nonzero
run_case fixed-logic fixed_logic.sv 1800-2017 zero
run_case fixed-wire fixed_wire.v 1364-2005 zero
run_case fixed-proc fixed_proc.v 1364-2005 zero

if [ "$status" -eq 0 ]; then
    printf '\nPASS: CONTASSREG reproduced; all three fixes exited 0\n'
fi
exit "$status"
