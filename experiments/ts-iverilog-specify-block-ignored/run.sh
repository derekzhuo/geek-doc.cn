#!/usr/bin/env bash
set -u

printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-31'
printf '%s\n' '# host-toolchain: Icarus Verilog 13.0 / macOS'

echo '$ iverilog -g2012 -s tb_path -o simv_path tb_path.v && vvp simv_path'
iverilog -g2012 -s tb_path -o simv_path tb_path.v && vvp simv_path
path_status=$?

echo '$ iverilog -g2012 -s tb_timing -o simv_timing tb_timing.v && vvp simv_timing'
iverilog -g2012 -s tb_timing -o simv_timing tb_timing.v && vvp simv_timing
timing_status=$?

printf 'RESULT path_status=%d timing_status=%d\n' "$path_status" "$timing_status"
if [ "$path_status" -ne 0 ] || [ "$timing_status" -ne 0 ]; then
    exit 1
fi
