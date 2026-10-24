#!/usr/bin/env bash
# exp-round-robin-arbiter-sim: fixed vs round-robin grant distribution
set -u
SLUG="exp-round-robin-arbiter-sim"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

iverilog -g2012 -o sim.vvp "$SRC_DIR/arb_fixed.v" "$SRC_DIR/arb_rr.v" "$SRC_DIR/tb_arbiter.v"
vvp sim.vvp | tee sim.log

if grep -q 'RESULT: PASS' sim.log; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
