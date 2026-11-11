#!/usr/bin/env bash
set -euo pipefail

printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: Docker geek-eda:0.2 / Yosys 0.33\n'

for top in async_ram sync_ram; do
    printf '\n===== CASE %s =====\n' "$top"
    docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 \
        yosys -Q -T -p "read_verilog ${top}.v; synth_ecp5 -top ${top}" \
        2>&1 | grep -E '^(mapping memory|=== |   Number of (wires|cells):|     (DP16KD|PDPW16KD|DPR16X4C|TRELLIS_DPR16X4|LUT4|TRELLIS_FF)|Warning:|ERROR:)'
done
