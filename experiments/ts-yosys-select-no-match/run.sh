#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

step() {
    printf '\n--- %s ---\n' "$1"; shift
    printf '$ yosys -p %q\n' "$*"
    yosys -p "$*" 2>&1
    printf 'exit code: %d\n' "$?"
}

step "1. plain select with wrong hierarchy is silently empty" "read_verilog top.v; synth -top top -run coarse; select top/u_missing/*"
step "2. stat on the empty selection only prints a soft warning" "read_verilog top.v; synth -top top -run coarse; stat top/u_missing/*"
step "3. assert-min turns the empty match into a hard ERROR" "read_verilog top.v; synth -top top -run coarse; select -assert-min 1 top/u_missing/*"
step "4. fixed: correct hierarchy path passes the same assertion" "read_verilog top.v; synth -top top -run coarse; select -assert-min 1 top/*"
