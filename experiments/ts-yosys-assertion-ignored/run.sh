#!/usr/bin/env bash
set -u

YOSYS=(docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 yosys)

printf '$ docker run --rm ... geek-eda:0.2 yosys -V\n'
"${YOSYS[@]}" -V

run_case() {
    local file="$1"
    local top="$2"
    local mode="$3"
    local label="$4"
    local read_args="-sv"
    if [[ "$mode" == "formal" ]]; then
        read_args="-sv -formal"
    elif [[ "$mode" == "noassert" ]]; then
        read_args="-sv -noassert"
    fi

    printf '\n===== %s =====\n' "$label"
    printf '$ yosys -p "read_verilog %s %s; hierarchy -check -top %s; proc; check; stat"\n' \
        "$read_args" "$file" "$top"
    "${YOSYS[@]}" -p "read_verilog $read_args $file; hierarchy -check -top $top; proc; check; stat"
    local status=$?
    printf '%s_exit=%s\n' "$label" "$status"
    return "$status"
}

expect_frontend_error() {
    local mode="$1"
    local label="$2"
    local read_args="-sv"
    if [[ "$mode" == "formal" ]]; then
        read_args="-sv -formal"
    fi

    printf '\n===== %s =====\n' "$label"
    printf '$ yosys -p "read_verilog %s concurrent_clocked.sv"\n' "$read_args"
    "${YOSYS[@]}" -p "read_verilog $read_args concurrent_clocked.sv"
    local status=$?
    printf '%s_exit=%s\n' "$label" "$status"
    if [[ "$status" -eq 0 ]]; then
        return 1
    fi
    return 0
}

failures=0
run_case immediate_assert.sv immediate_assert noassert immediate_noassert || failures=$((failures + 1))
run_case immediate_assert.sv immediate_assert plain immediate_plain || failures=$((failures + 1))
run_case immediate_assert.sv immediate_assert formal immediate_formal || failures=$((failures + 1))
run_case concurrent_assert.sv concurrent_assert noassert concurrent_noassert || failures=$((failures + 1))
run_case concurrent_assert.sv concurrent_assert plain concurrent_plain || failures=$((failures + 1))
run_case concurrent_assert.sv concurrent_assert formal concurrent_formal || failures=$((failures + 1))
expect_frontend_error plain clocked_plain || failures=$((failures + 1))
expect_frontend_error formal clocked_formal || failures=$((failures + 1))

printf '\nresult=ordinary-read-versus-formal-read comparison complete\n'
printf 'unexpected_failures=%s\n' "$failures"
exit "$failures"
