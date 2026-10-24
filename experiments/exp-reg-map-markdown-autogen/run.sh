#!/usr/bin/env bash
# exp-reg-map-markdown-autogen: md table -> regs.vh + regs.h, then iverilog proof
set -u
SLUG="exp-reg-map-markdown-autogen"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

PY=/opt/eda-venv/bin/python
[ -x "$PY" ] || PY=python3
echo "python: $PY"

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

"$PY" "$SRC_DIR/gen_regs.py" "$SRC_DIR/regs.md" regs.vh regs.h
echo "--- regs.vh ---"; cat regs.vh
echo "--- regs.h ---";  cat regs.h

echo "=== compile consumer module with generated header ==="
iverilog -g2012 -I "$WORK" -o reg_user.vvp "$SRC_DIR/reg_user.v" && echo "iverilog compile OK"

if [ -s reg_user.vvp ] && grep -q 'REG_CTRL_ADDR' regs.vh && grep -q 'REG_CTRL_ADDR' regs.h; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
