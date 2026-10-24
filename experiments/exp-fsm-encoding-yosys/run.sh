#!/usr/bin/env bash
# exp-fsm-encoding-yosys: binary vs one-hot vs gray FSM encoding, yosys stat x3
set -u
SLUG="exp-fsm-encoding-yosys"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

ok=1
for TOP in fsm_bin fsm_onehot fsm_gray; do
    echo "=== synth $TOP ==="
    yosys -p "read_verilog $SRC_DIR/fsm_variants.v; synth -top $TOP; stat" 2>&1 | tee "stat_$TOP.log"
    grep -E 'Number of cells|Number of wires' "stat_$TOP.log" || ok=0
done

echo "=== encoding comparison table ==="
printf '%-12s %-8s %-8s %-8s\n' ENCODING CELLS WIRES DFF_CELLS
for TOP in fsm_bin fsm_onehot fsm_gray; do
    C=$(grep -E 'Number of cells' "stat_$TOP.log" | awk '{print $NF}')
    W=$(grep -E 'Number of wires' "stat_$TOP.log" | awk '{print $NF}')
    D=$(grep -c '\$_DFF' "stat_$TOP.log" || true)
    printf '%-12s %-8s %-8s %-8s\n' "$TOP" "$C" "$W" "$D"
done

if [ "$ok" = 1 ]; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
