#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
set +e

printf -- "--- 1. zero-resistance voltage source loop ---\n$ ngspice -b bad.cir\n"
ngspice -b bad.cir 2>&1
printf "exit code: %d\n" "$?"
printf -- "\n--- 2. fix A: keep one voltage source ---\n$ ngspice -b fixed_remove.cir\n"
ngspice -b fixed_remove.cir 2>&1 | grep -E "Error|voltage|node" | head -6
printf "exit code: %d\n" "${PIPESTATUS[0]}"
printf -- "\n--- 3. fix B: series resistor makes the loop uniquely solvable ---\n$ ngspice -b fixed_resistor.cir\n"
ngspice -b fixed_resistor.cir 2>&1 | grep -E "Error|branch|v1#" | head -6
printf "exit code: %d\n" "${PIPESTATUS[0]}"
