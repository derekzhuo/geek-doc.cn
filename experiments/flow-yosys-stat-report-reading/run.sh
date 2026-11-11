#!/bin/bash
# Reproduce every `stat` output quoted in the article.
set -e

echo "## yosys version:"
yosys -V

mid_stat () {
    local src="$1"
    local top="$2"
    echo
    echo "================ RTL-level stat (proc; opt): ${top} ================"
    printf 'read_verilog %s\nhierarchy -top %s\nproc\nopt\nstat\n' "$src" "$top" > /tmp/mid.ys
    yosys -s /tmp/mid.ys 2>&1 | awk '/Printing statistics/{p=1} p' | head -40
}

full_synth () {
    local src="$1"
    local top="$2"
    echo
    echo "================ gate-level stat (full synth): ${top} ================"
    yosys -p "read_verilog ${src}; synth -top ${top}; stat" 2>&1 | awk '/2.25. Printing statistics/{p=1} p' | head -45
}

mid_stat counter.v counter
mid_stat fifo.v fifo
mid_stat fsm3.v fsm3

full_synth counter.v counter
full_synth fifo.v fifo
full_synth fsm3.v fsm3
full_synth latch.v latch_demo

echo
echo "================ memory kept until memory_collect: ram16x8 ================"
yosys -s ram_midstat.ys 2>&1 | awk '/6. Printing statistics/{p=1} p' | head -25

echo
echo "================ stat -tech cmos: counter ================"
yosys -s area_cmos.ys 2>&1 | awk '/3. Printing statistics/{p=1} p' | head -30

for top in counter fifo fsm3; do
    echo
    echo "================ stat -liberty tiny.lib: ${top} ================"
    sed "s/%TOP%/${top}/" area_lib.ys > /tmp/lib.ys
    yosys -s /tmp/lib.ys 2>&1 | awk '/8. Printing statistics/{p=1} p' | head -40
done
