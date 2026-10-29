#!/usr/bin/env bash
set -u

printf '# command: bash ./run.sh\n'
printf '# date: %s\n' "$(date -u +%F)"
printf '# host-toolchain: geek-eda:0.2 / %s\n' "$(yosys -V)"

run_case() {
    local cmd="$1"
    printf '\n# command: %s\n' "$cmd"
    eval "$cmd" 2>&1
    local rc=$?
    printf '# exit_code: %s\n' "$rc"
}

run_case "yosys -Q -T -p 'read_verilog top_inferred.v; synth_ice40 -top top -noabc -json /tmp/top_inferred.json; check; stat'"
run_case "yosys -Q -T -p 'read_verilog internal_tristate.v; synth_ice40 -top top -noabc; check; stat'"
run_case "yosys -Q -T -p 'read_verilog top_explicit.v; synth_ice40 -top top -noabc; check; stat'"
run_case "yosys -Q -T -p 'read_verilog top_active_low.v; synth_ice40 -top top -noabc; check; stat'"
run_case "yosys -Q -T -p 'read_verilog internal_tristate.v; hierarchy -top top; proc; opt; tribuf -logic; check; stat'"
