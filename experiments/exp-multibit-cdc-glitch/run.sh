#!/usr/bin/env bash
# exp-multibit-cdc-glitch: direct multibit sync glitch vs gray-code sync
set -u
SLUG="exp-multibit-cdc-glitch"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

iverilog -g2012 -o sim.vvp "$SRC_DIR/src_counter.v" "$SRC_DIR/tb_multibit_cdc.v"
vvp sim.vvp | tee sim.log
cp -f multibit_cdc.vcd "$OUT/" 2>/dev/null || true

echo "illegal-intermediate evidence lines:"
grep -c 'DIRECT illegal' sim.log || true

if grep -q 'RESULT: PASS' sim.log; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
