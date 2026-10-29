#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if command -v yosys >/dev/null 2>&1; then
    YOSYS=(yosys)
elif command -v docker >/dev/null 2>&1; then
    YOSYS=(docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 yosys)
else
    printf 'error: yosys or docker is required\n' >&2
    exit 2
fi

printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: %s / %s\n' \
    "$([ "${YOSYS[0]}" = docker ] && printf 'Docker geek-eda:0.2' || printf 'local Yosys')" \
    "$("${YOSYS[@]}" -V)"

run_expect() {
    local expected="$1"
    local label="$2"
    local script="$3"
    local rc

    printf '\n=== %s ===\n' "$label"
    printf "$ yosys -p '%s'\n" "$script"
    set +e
    "${YOSYS[@]}" -p "$script"
    rc=$?
    set -e
    printf 'exit=%s\n' "$rc"
    if [ "$rc" -ne "$expected" ]; then
        printf 'FAIL: expected exit=%s, got exit=%s\n' "$expected" "$rc" >&2
        return 1
    fi
}

run_expect 1 conflict \
    'read_verilog top.v pulse_a.v pulse_b.v; hierarchy -check -top top; check -assert'
run_expect 1 repeated_input \
    'read_verilog top.v pulse_a.v pulse_a.v; hierarchy -check -top top; check -assert'
run_expect 1 defer_is_not_dedup \
    'read_verilog -defer top.v pulse_a.v pulse_b.v; hierarchy -check -top top; check -assert'
run_expect 0 lib_replaces_blackbox \
    'read_verilog -lib pulse_a.v pulse_b.v'
run_expect 0 fixed_dedup \
    'read_verilog top.v pulse_a.v; hierarchy -check -top top; synth -top top; check -assert'
run_expect 0 fixed_rename \
    'read_verilog top_fixed.v pulse_a.v pulse_or.v; hierarchy -check -top top; synth -top top; check -assert'

printf '\nPASS: duplicate errors reproduced; dedup and rename designs synthesized successfully\n'
