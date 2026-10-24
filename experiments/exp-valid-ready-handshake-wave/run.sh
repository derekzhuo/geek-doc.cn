#!/usr/bin/env bash
# exp-valid-ready-handshake-wave: backpressure handshake integrity + VCD
set -u
SLUG="exp-valid-ready-handshake-wave"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

iverilog -g2012 -o sim.vvp "$SRC_DIR/vr_pipe.v" "$SRC_DIR/tb_valid_ready.v"
vvp sim.vvp | tee sim.log
cp -f valid_ready.vcd "$OUT/" 2>/dev/null || true

if grep -q 'RESULT: PASS' sim.log; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
