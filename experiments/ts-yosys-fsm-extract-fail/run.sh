#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p .build

printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: Docker geek-eda:0.2 / Yosys 0.33 / Icarus Verilog 12.0\n'

for design in standard exported arithmetic; do
  printf '\n$ docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 yosys -p "read_verilog %s.v; synth -top %s; stat; write_verilog .build/%s-netlist.v"\n' "$design" "$design" "$design"
  docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 \
    yosys -p "read_verilog $design.v; synth -top $design; stat; write_verilog .build/$design-netlist.v" \
    2>&1 | grep -vE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.'
  printf 'synthesis_exit=0\n'

  printf '\n$ docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 sh -lc "iverilog -g2012 -DDUT=%s -s tb -o .build/%s.vvp .build/%s-netlist.v tb.v && vvp .build/%s.vvp"\n' "$design" "$design" "$design" "$design"
  docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 \
    sh -lc "iverilog -g2012 -DDUT=$design -s tb -o .build/$design.vvp .build/$design-netlist.v tb.v && vvp .build/$design.vvp"
  printf 'simulation_exit=0\n'
done
