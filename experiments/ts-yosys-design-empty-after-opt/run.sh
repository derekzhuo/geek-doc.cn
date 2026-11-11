#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

step() {
    printf '\n--- %s ---\n' "$1"; shift
    printf '$ yosys -p %q\n' "$*"
    yosys -p "$*" 2>&1
    printf 'exit code: %d\n' "$?"
}

step "1. full synth purges the unused orphan module" "read_verilog two_mod.v; synth -top top"
step "2. stat on the purged module is only a soft warning" "read_verilog two_mod.v; synth -top top; stat orphan"
step "3. assert selection on the purged module is a hard ERROR" "read_verilog two_mod.v; synth -top top; select -assert-min 1 orphan/*"
step "4. dangling single module keeps ports but loses all cells" "read_verilog dangling.v; synth -top dangling; stat dangling"
step "5. fixed: connected module retains its cell after synth" "read_verilog connected.v; synth -top connected; stat connected"
