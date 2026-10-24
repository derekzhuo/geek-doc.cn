#!/usr/bin/env bash
# exp-tcl-scripting-yosys-openroad: yosys script-mode steps (+ openroad probe)
set -u
SLUG="exp-tcl-scripting-yosys-openroad"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"
cp "$SRC_DIR/demo.v" .

ok=1
for s in s1_read s2_stat s3_select_rename s4_synth_write; do
    echo "================ yosys -s $s.ys ================"
    yosys -s "$SRC_DIR/$s.ys" 2>&1 | tee "step_$s.log"
    rc=${PIPESTATUS[0]}
    echo "yosys exit code for $s: $rc"
    [ "$rc" -eq 0 ] || ok=0
done

ls -l synth_out.v synth_out.json 2>/dev/null || { echo "synth outputs missing"; ok=0; }

echo "=== openroad probe ==="
if command -v openroad >/dev/null 2>&1; then
    openroad -version 2>&1 | head -2
else
    echo "SKIP: openroad not installed in this image (eda-golden-v1 ships yosys only)"
fi

if [ "$ok" = 1 ]; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
