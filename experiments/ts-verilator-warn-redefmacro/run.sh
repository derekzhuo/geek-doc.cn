#!/usr/bin/env bash
set -u

fail=0
run_case() {
    local name="$1"
    local expected="$2"
    local dir="$3"
    echo "=== ${name} ==="
    echo "$ verilator --lint-only -Wall -Wwarn-REDEFMACRO -I${dir} ${dir}/top.sv"
    verilator --lint-only -Wall -Wwarn-REDEFMACRO "-I${dir}" "${dir}/top.sv" 2>&1
    local rc=$?
    echo "${name} exit=${rc}"
    if [ "${rc}" -ne "${expected}" ]; then
        echo "FAIL: ${name} expected exit=${expected}, got ${rc}"
        fail=1
    fi
    echo
}

echo "=== broken-default ==="
echo "$ verilator --lint-only -Ibroken_conflict broken_conflict/top.sv"
verilator --lint-only -Ibroken_conflict broken_conflict/top.sv 2>&1
default_rc=$?
echo "broken-default exit=${default_rc}"
if [ "${default_rc}" -ne 1 ]; then
    echo "FAIL: broken-default expected exit=1, got ${default_rc}"
    fail=1
fi
echo

run_case broken-same 0 broken
run_case broken-conflict 1 broken_conflict
run_case fixed-guard 0 fixed_guard
run_case fixed-pragma 0 fixed_pragma

if [ "${fail}" -eq 0 ]; then
    echo "PASS: REDEFMACRO reproduced; include guard and pragma once exited 0"
fi
exit "${fail}"
