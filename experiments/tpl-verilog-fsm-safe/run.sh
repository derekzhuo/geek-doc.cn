#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-31'
printf '%s\n' '# host-toolchain: Icarus Verilog 13.0 / macOS'
trap 'rm -f safe_fsm_sim' EXIT

iverilog -g2012 -Wall -s tb_safe_fsm -o safe_fsm_sim safe_fsm.v tb_safe_fsm.v
vvp safe_fsm_sim
