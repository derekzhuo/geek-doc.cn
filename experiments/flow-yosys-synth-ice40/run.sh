#!/usr/bin/env bash
# iCE40 完整链路：Yosys synth_ice40 -> nextpnr-ice40 -> icepack
set -euo pipefail

IMAGE="${IMAGE:-geek-eda:0.4-flow}"
RUN="docker run --rm -v $PWD:/work -w /work ${IMAGE}"

echo "### 1. tool versions"
${RUN} yosys -V
${RUN} nextpnr-ice40 --version
echo

echo "### 2. yosys: read_verilog + synth_ice40 -json"
${RUN} yosys -s synth.ys
echo

echo "### 3. nextpnr-ice40: place and route (hx1k / tq144)"
${RUN} nextpnr-ice40 --hx1k --package tq144 \
    --json top.json --pcf top.pcf --asc top.asc
echo

echo "### 4. icepack: pack .asc into binary bitstream"
${RUN} icepack top.asc top.bin
${RUN} sh -c 'wc -c top.bin'
echo

echo "### ALL DONE: top.json -> top.asc -> top.bin"
