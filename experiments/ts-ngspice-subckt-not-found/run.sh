#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
set +e

printf -- "--- 1. missing subcircuit definition ---\n$ ngspice -b bad.cir\n"
ngspice -b bad.cir 2>&1
printf "exit code: %d\n" "$?"
printf -- "\n--- 2. fixed: .include amp.cir provides the subckt ---\n$ ngspice -b fixed.cir\n"
ngspice -b fixed.cir 2>&1 | tail -12
printf "exit code: %d\n" "${PIPESTATUS[0]}"
