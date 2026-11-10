#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
set +e

printf -- "--- 1. measure references a vector that does not exist ---\n$ ngspice -b meas_bad.cir\n"
ngspice -b meas_bad.cir 2>&1
printf "exit code: %d\n" "$?"
printf -- "\n--- 2. fixed: reference the real node v(out) ---\n$ ngspice -b meas_fixed.cir\n"
ngspice -b meas_fixed.cir 2>&1 | grep -E "tcross|Error"
printf "exit code: %d\n" "${PIPESTATUS[0]}"
