#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
set +e

printf -- "--- 1. MOS devices without .model cards ---\n$ ngspice -b inverter_bad.cir\n"
ngspice -b inverter_bad.cir 2>&1
printf "exit code: %d\n" "$?"
printf -- "\n--- 2. fixed: level 1 model cards, DC sweep prints transfer curve ---\n$ ngspice -b inverter_fixed.cir\n"
ngspice -b inverter_fixed.cir 2>&1 | sed -n "/Index/,/^$/p"
printf "exit code: %d\n" "${PIPESTATUS[0]}"
