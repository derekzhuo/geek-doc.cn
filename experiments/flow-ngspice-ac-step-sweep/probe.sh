#!/usr/bin/env bash
set -uo pipefail

printf '%s\n' '$ ngspice --version'
ngspice --version
printf '%s\n' '$ ngspice -b step_probe.cir'
output=$(ngspice -b step_probe.cir 2>&1)
status=$?
printf '%s\n' "$output"
printf 'PROBE_EXIT=%s\n' "$status"
if [[ "$status" -ne 1 ]] || ! grep -Fq "unimplemented dot command '.step'" <<<"$output"; then
  printf '%s\n' 'Expected exit 1 with the exact unsupported .step diagnostic.'
  exit 1
fi
