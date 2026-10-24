#!/usr/bin/env bash
# exp-cocotb-minimal-testbench: minimal cocotb TB on icarus via eda venv
set -u
SLUG="exp-cocotb-minimal-testbench"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

export PATH="/opt/eda-venv/bin:$PATH"
echo "cocotb-config: $(command -v cocotb-config || echo MISSING)"

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"
cp "$SRC_DIR/counter.v" "$SRC_DIR/test_counter.py" "$SRC_DIR/Makefile" .

make 2>&1 | tee make.log

echo "=== cocotb summary lines ==="
grep -E 'Test Passed|Test Failed|TESTS=|PASS=|FAILURES|passed' make.log || true

# pass marker differs by cocotb version: 1.x prints "Test Passed", 2.x prints a "PASS=N" summary
if { grep -qE 'Test Passed' make.log || grep -qE 'PASS=[1-9]' make.log; } \
   && ! grep -qE 'Test Failed|FAIL=[1-9]' make.log; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
