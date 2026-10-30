#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/out"

for tool in iverilog vvp; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'error: %s was not found in PATH; install Icarus Verilog first.\n' "$tool" >&2
        exit 1
    fi
done

mkdir -p "$OUT_DIR"
iverilog -g2012 -o "$OUT_DIR/sim.vvp" \
    "$ROOT_DIR/rtl/sync_fifo.v" "$ROOT_DIR/tb/tb_sync_fifo.v"

cd "$OUT_DIR"
vvp sim.vvp 2>&1 | tee sim.log
grep -q '^RESULT: PASS$' sim.log
printf '\nWaveform: %s\nLog:      %s\n' "$OUT_DIR/sync_fifo.vcd" "$OUT_DIR/sim.log"
