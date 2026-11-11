#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
set +e

printf -- '--- 1. export a healthy JSON netlist ---\n'
printf '$ yosys -s export.ys\n'
yosys -s export.ys >/dev/null 2>&1
printf 'counter.json: %s bytes\n' "$(wc -c < counter.json)"
head -c 400 counter.json > counter_truncated.json

printf -- '\n--- 2. read_json on the truncated file fails ---\n'
printf '$ yosys -p "read_json counter_truncated.json"\n'
yosys -p "read_json counter_truncated.json" 2>&1
printf 'exit code: %d\n' "$?"

printf -- '\n--- 3. read_json on the intact file passes, stat follows ---\n'
printf '$ yosys -p "read_json counter.json; stat"\n'
yosys -p "read_json counter.json; stat" 2>&1 | tail -8
printf 'exit code: %d\n' "${PIPESTATUS[0]}"
