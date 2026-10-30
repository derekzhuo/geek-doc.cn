#!/usr/bin/env bash
set -euo pipefail

printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: Docker geek-eda:0.2 / Yosys 0.33\n'
docker run --rm geek-eda:0.2 yosys -V | sed 's/^/version: /'

docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 \
    yosys -s roundtrip.ys

printf '%s\n' '-- selected JSON fields --'
grep -E '"(parameter_default_values|WIDTH|RESET_VALUE|keep|keep_hierarchy|mark_debug)"' roundtrip.json
printf '%s\n' '-- round-trip Verilog fields --'
grep -E '^module |keep_hierarchy|mark_debug|5.h05|u_lane' roundtrip_out.v
printf '%s\n' '-- generated artifacts --'
ls -l roundtrip.json roundtrip_out.v
printf '%s\n' 'result=JSON read-back completed; stat/check/write_verilog finished for this sample'
