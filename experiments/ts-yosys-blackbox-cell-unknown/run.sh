#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

unknown_cmd="read_verilog top.v; hierarchy -check -top top; check; stat"
blackbox_cmd="read_verilog top.v blackbox.v; hierarchy -check -top top; check; stat"
implementation_cmd="read_verilog top.v vendor_adder.v; hierarchy -check -top top; proc; opt; check; stat"

printf '# command: yosys -Q -T -p '\''%s'\''\n' "$unknown_cmd"
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: %s / %s\n' "${HOST_TOOLCHAIN:-$(uname -srm)}" "$(yosys -V)"

run_case() {
    local label="$1"
    local expected="$2"
    local command="$3"
    local status

    printf '\n=== CASE: %s ===\n' "$label"
    if [[ "$label" != "unknown-module" ]]; then
        printf '# command: yosys -Q -T -p '\''%s'\''\n' "$command"
    fi

    set +e
    yosys -Q -T -p "$command" 2>&1
    status=$?
    set -e
    printf 'EXIT_CODE=%d\n' "$status"

    if [[ "$status" -ne "$expected" ]]; then
        printf 'UNEXPECTED_EXIT: expected=%d actual=%d\n' "$expected" "$status"
        return 1
    fi
}

run_case "unknown-module" 1 "$unknown_cmd"
run_case "explicit-blackbox" 0 "$blackbox_cmd"
run_case "real-implementation" 0 "$implementation_cmd"
printf '\nSUMMARY: PASS (unknown=1, blackbox=0, implementation=0)\n'
