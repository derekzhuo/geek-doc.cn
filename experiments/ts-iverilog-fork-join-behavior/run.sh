#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")"

printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-31'
printf '%s\n' '# host-toolchain: Icarus Verilog 13.0 / macOS'

iverilog -g2012 -Wall -s tb -o fork_join_behavior.vvp fork_join_behavior.sv
vvp fork_join_behavior.vvp
