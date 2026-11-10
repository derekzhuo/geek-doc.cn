#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

run_step() {
    printf '\n--- %s ---\n' "$1"; shift
    printf '$ verilator %s\n' "$*"
    verilator "$@" 2>&1
    printf 'exit code: %d\n' "$?"
}

run_step "1. package file missing from command line: PKGNODECL" --lint-only rtl/top.sv
run_step "2. -y module search dir does not resolve packages" --lint-only -y rtl rtl/top.sv
run_step "3. fixed: list iopkg.sv before top.sv on the command line" --lint-only rtl/iopkg.sv rtl/top.sv
