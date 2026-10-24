#!/usr/bin/env bash
# exp-yosys-verilator-quickstart: 4-step flow on one module
set -u
SLUG="exp-yosys-verilator-quickstart"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

ok=1

echo "############ STEP 1/4: yosys synthesis + stat ############"
yosys -p "read_verilog $SRC_DIR/seg7_demo.v; synth -top seg7_demo; stat" 2>&1 | tee step1_yosys.log
grep -q 'Number of cells' step1_yosys.log || ok=0

echo "############ STEP 2/4: verilator lint ############"
verilator --lint-only "$SRC_DIR/seg7_demo.v" 2>&1 | tee step2_lint.log
echo "lint exit: ${PIPESTATUS[0]} (0 = clean)"

echo "############ STEP 3/4: iverilog simulation ############"
iverilog -g2012 -o sim.vvp "$SRC_DIR/seg7_demo.v" "$SRC_DIR/tb_seg7.v"
vvp sim.vvp | tee step3_sim.log
grep -q 'RESULT: PASS' step3_sim.log || ok=0

echo "############ STEP 4/4: VCD waveform artifact ############"
ls -l seg7_demo.vcd || ok=0
cp -f seg7_demo.vcd "$OUT/" 2>/dev/null || true
head -20 seg7_demo.vcd || true

if [ "$ok" = 1 ]; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
