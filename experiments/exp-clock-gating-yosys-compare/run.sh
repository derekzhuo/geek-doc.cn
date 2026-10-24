#!/usr/bin/env bash
# exp-clock-gating-yosys-compare: enable-mux vs gated-clock, yosys stat compare
set -u
SLUG="exp-clock-gating-yosys-compare"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

echo "=== synth style A: enable register ==="
yosys -p "read_verilog $SRC_DIR/reg_en.v; synth -top reg_en; stat" 2>&1 | tee stat_en.log

echo "=== synth style B: explicit gated clock ==="
yosys -p "read_verilog $SRC_DIR/reg_gated.v; synth -top reg_gated; stat" 2>&1 | tee stat_gated.log

echo "=== cell count comparison ==="
A=$(grep -E 'Number of cells' stat_en.log    | awk '{print $NF}')
B=$(grep -E 'Number of cells' stat_gated.log | awk '{print $NF}')
AW=$(grep -E 'Number of wires' stat_en.log    | awk '{print $NF}')
BW=$(grep -E 'Number of wires' stat_gated.log | awk '{print $NF}')
echo "style A (enable)   : cells=$A wires=$AW"
echo "style B (gated clk): cells=$B wires=$BW"
echo "--- style A cell types ---"
grep -A12 'Number of cells' stat_en.log | tail -10 || true
echo "--- style B cell types ---"
grep -A12 'Number of cells' stat_gated.log | tail -10 || true

if [ -n "$A" ] && [ -n "$B" ]; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
