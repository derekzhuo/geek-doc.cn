#!/usr/bin/env bash
# exp-waveform-png-gtkwave-surfer: VCD -> (PNG if headless gtkwave works) else
# wavedrom WaveJSON fallback. No X11 allowed.
set -u
SLUG="exp-waveform-png-gtkwave-surfer"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

PY=/opt/eda-venv/bin/python
[ -x "$PY" ] || PY=python3

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

echo "=== step 1: produce VCD with iverilog ==="
iverilog -g2012 -o wave.vvp "$SRC_DIR/tb_wave.v"
vvp wave.vvp
ls -l wave_demo.vcd

echo "=== step 2: probe gtkwave ==="
if command -v gtkwave >/dev/null 2>&1; then
    which gtkwave
    # try headless conversion via tcl script; needs X on most builds
    cat > dump.tcl <<'EOF'
set nf [gtkwave::loadFile wave_demo.vcd]
gtkwave::/Time/Zoom/Zoom_Full
EOF
    if gtkwave --script dump.tcl --dumpfile out.png wave_demo.vcd 2>&1 | tee gtkwave.log && [ -s out.png ]; then
        echo "PNG produced headlessly: out.png"
        cp out.png "$OUT/"
    else
        echo "FALLBACK: gtkwave cannot render PNG without X on this image; using wavedrom JSON path"
        "$PY" "$SRC_DIR/vcd2wavedrom.py" wave_demo.vcd wave.json clk,req,ack,cnt 10000 40 cnt:4
        cp wave.json "$OUT/"
    fi
else
    echo "FALLBACK: gtkwave not installed; using wavedrom JSON path"
    "$PY" "$SRC_DIR/vcd2wavedrom.py" wave_demo.vcd wave.json clk,req,ack,cnt 10000 40 cnt:4
    cp wave.json "$OUT/"
fi

echo "=== step 3: verify artifact ==="
if [ -s "$OUT/wave.json" ]; then
    head -30 "$OUT/wave.json"
    echo "artifact: wave.json (wavedrom WaveJSON, render with wavedrom-cli on the doc build host)"
    echo "RESULT: PASS"
elif [ -s "$OUT/out.png" ]; then
    echo "artifact: out.png"
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
