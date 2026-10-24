#!/usr/bin/env bash
# exp-async-fifo-depth-burst-calc: good depth vs half depth burst test
set -u
SLUG="exp-async-fifo-depth-burst-calc"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

echo "=== GROUP GOOD: AW=4 (depth 16, >= required 12) ==="
iverilog -g2012 -o fifo_good.vvp -Ptb_async_fifo.AW=4 "$SRC_DIR/async_fifo.v" "$SRC_DIR/tb_async_fifo.v"
vvp fifo_good.vvp | tee good.log

echo "=== GROUP BAD: AW=2 (depth 4, half of good) ==="
iverilog -g2012 -o fifo_bad.vvp -Ptb_async_fifo.AW=2 "$SRC_DIR/async_fifo.v" "$SRC_DIR/tb_async_fifo.v"
vvp fifo_bad.vvp | tee bad.log

GOOD=$(grep -c 'GROUP_RESULT: PASS' good.log || true)
BADFAIL=$(grep -c 'GROUP_RESULT: FAIL' bad.log || true)
DROPS=$(grep -c 'OVERFLOW drop' bad.log || true)
echo "good_pass_lines=$GOOD bad_fail_lines=$BADFAIL bad_overflow_drops=$DROPS"

if [ "$GOOD" -ge 1 ] && [ "$BADFAIL" -ge 1 ] && [ "$DROPS" -ge 1 ]; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
