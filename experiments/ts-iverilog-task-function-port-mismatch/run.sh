#!/usr/bin/env bash
set -u

cd -- "$(dirname -- "$0")"
mkdir -p build
failures=0

compile_case() {
    local name="$1"
    local expected="$2"
    printf '$ iverilog -g2012 -o build/%s.vvp %s.sv\n' "$name" "$name"
    iverilog -g2012 -o "build/${name}.vvp" "${name}.sv"
    local rc=$?
    printf '%s compile exit=%d (expected=%d)\n' "$name" "$rc" "$expected"
    if [ "$rc" -ne "$expected" ]; then
        failures=$((failures + 1))
    fi
}

run_case() {
    local name="$1"
    local expected="$2"
    printf '$ vvp build/%s.vvp\n' "$name"
    vvp "build/${name}.vvp"
    local rc=$?
    printf '%s simulation exit=%d (expected=%d)\n' "$name" "$rc" "$expected"
    if [ "$rc" -ne "$expected" ]; then
        failures=$((failures + 1))
    fi
}

compile_case task_count_bad 1
compile_case task_direction_bad 0
run_case task_direction_bad 0
compile_case function_count_bad 1
compile_case ports_fixed 0
run_case ports_fixed 0

if [ "$failures" -eq 0 ]; then
    printf 'PASS: all compile and simulation results matched expectations\n'
    exit 0
fi
printf 'FAIL: %d result(s) differed from expectations\n' "$failures"
exit 1
