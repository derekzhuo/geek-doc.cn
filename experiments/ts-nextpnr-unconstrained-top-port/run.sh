#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
set +e

printf -- '--- 0. synthesize for iCE40 ---\n$ yosys -s synth.ys\n'
yosys -s synth.ys >/dev/null 2>&1 && printf 'top.json ready: %s bytes\n' "$(wc -c < top.json)"

printf -- '\n--- 1. PCF missing the led constraint ---\n'
printf '$ nextpnr-ice40 --hx1k --package tq144 --json top.json --pcf bad.pcf --asc bad.asc\n'
nextpnr-ice40 --hx1k --package tq144 --json top.json --pcf bad.pcf --asc bad.asc 2>&1 | tail -5
printf 'exit code: %d\n' "${PIPESTATUS[0]}"

printf -- '\n--- 2. override switch downgrades the error to a warning ---\n'
printf '$ nextpnr-ice40 ... --pcf-allow-unconstrained\n'
nextpnr-ice40 --hx1k --package tq144 --json top.json --pcf bad.pcf --pcf-allow-unconstrained --asc override.asc 2>&1 | grep -E "Warning|ERROR"
printf 'exit code: %d\n' "${PIPESTATUS[0]}"

printf -- '\n--- 3. fixed PCF: place-and-route finishes, bitstream packs ---\n'
printf '$ nextpnr-ice40 ... --pcf fixed.pcf && icepack\n'
nextpnr-ice40 --hx1k --package tq144 --json top.json --pcf fixed.pcf --asc fixed.asc 2>&1 | tail -2
printf 'nextpnr exit code: %d\n' "${PIPESTATUS[0]}"
icepack fixed.asc fixed.bin && printf 'icepack ok: %s bytes\n' "$(wc -c < fixed.bin)"
