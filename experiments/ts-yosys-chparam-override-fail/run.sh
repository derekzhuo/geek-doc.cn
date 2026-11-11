#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

step() {
    printf '\n--- %s ---\n' "$1"; shift
    printf '$ yosys -s %s\n' "$1"
    yosys -s "$1" 2>&1
    printf 'exit code: %d\n' "$?"
}

step "1. override a parameter name that does not exist" chparam_bad.ys
step "2. fixed: override the real WIDTH parameter and verify with stat" chparam_fixed.ys
