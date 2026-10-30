#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
mkdir -p .build

run_shell() {
  printf '\n$ %s\n' "$1"
  eval "$1"
  status=$?
  printf 'exit=%d\n' "$status"
}

run_shell 'iverilog -g2005 -s tb -o .build/baseline.vvp params.v && vvp .build/baseline.vvp'
run_shell 'iverilog -g2005 -s tb -Ptb.dut.u_leaf.WIDTH=12 -o .build/width.vvp params.v && vvp .build/width.vvp'
run_shell 'iverilog -g2005 -s tb -Ptb.ROOT_VALUE=7 -Ptb.ROOT_LIMIT=20 -Ptb.dut.u_leaf.WIDTH=12 -Ptb.dut.u_leaf.DEPTH=9 -o .build/multi.vvp params.v && vvp .build/multi.vvp'
run_shell 'iverilog -g2005 -s tb_alt -Ptb_alt.ROOT_VALUE=5 -Ptb_alt.dut.u_leaf.DEPTH=6 -o .build/alt.vvp params.v && vvp .build/alt.vvp'
run_shell 'iverilog -g2005 -s tb -PWIDTH=12 -o .build/short-name.vvp params.v'
run_shell 'iverilog -g2005 -s tb -Ptb.missing.WIDTH=12 -o .build/bad-path.vvp params.v'
