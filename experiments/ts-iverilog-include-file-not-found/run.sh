#!/usr/bin/env bash
set -u

cd -- "$(dirname -- "$0")"
mkdir -p build
failures=0

run_case() {
    local label="$1"
    local expected="$2"
    shift 2
    printf '\n== %s ==\n' "$label"
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    "$@"
    local rc=$?
    printf '%s exit=%d (expected=%d)\n' "$label" "$rc" "$expected"
    if [ "$rc" -ne "$expected" ]; then
        failures=$((failures + 1))
    fi
}

run_case root-no-I 1 \
    iverilog -g2012 -s tb_include -o build/root-no-I.vvp src/top.sv

run_case root-src-only 1 \
    iverilog -g2012 -Isrc -s tb_include -o build/root-src-only.vvp src/top.sv

run_case root-with-I 0 \
    iverilog -g2012 -Isrc -Iinclude -s tb_include -o build/root-with-I.vvp src/top.sv
run_case root-with-I-sim 0 vvp build/root-with-I.vvp

run_case src-cwd-no-I 1 \
    bash -c 'cd src && iverilog -g2012 -s tb_include -o ../build/src-cwd-no-I.vvp top.sv'

run_case src-cwd-with-I 0 \
    bash -c 'cd src && iverilog -g2012 -I../include -s tb_include -o ../build/src-cwd-with-I.vvp top.sv'
run_case src-cwd-with-I-sim 0 vvp build/src-cwd-with-I.vvp

printf '\n'
if [ "$failures" -eq 0 ]; then
    printf 'PASS: all include-path cases matched expected exit codes\n'
    exit 0
fi
printf 'FAIL: %d case(s) did not match expected exit codes\n' "$failures"
exit 1
