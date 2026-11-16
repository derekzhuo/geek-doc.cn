#!/usr/bin/env bash
set -u

cd "$(dirname "$0")"

cc -std=c11 -Wall -Wextra -o stats stats.c || exit 1

pass=0
fail=0

run_case() {
    local name="$1" input="$2" expected="$3"
    local actual
    actual=$(printf '%s' "$input" | ./stats)
    if [ "$actual" = "$expected" ]; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name (expected '$expected', got '$actual')"
        fail=$((fail + 1))
    fi
}

run_case "normal sequence" "1 2 3 -1" "avg=2.00"
run_case "single element" "5 -1" "avg=5.00"
run_case "empty sequence" "-1" "avg=0.00"

echo "----------------"
echo "PASS: $pass  FAIL: $fail"
[ "$fail" -eq 0 ]
