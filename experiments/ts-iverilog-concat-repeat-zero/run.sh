#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

echo '# command: bash run.sh'
echo '# date: 2026-10-31'
echo '# host-toolchain: Mac mini M4 / macOS 15 / Icarus Verilog 13.0'

echo
echo '[1/2] Reproduce EXTRA=0 with the unconditional repeat'
echo '$ iverilog -g2012 -s broken_top -o broken_simv broken.v'
iverilog -g2012 -s broken_top -o broken_simv broken.v 2>&1
broken_status=$?
echo "exit_status=$broken_status"

echo
echo '[2/2] Compile and run the generate-based fix'
echo '$ iverilog -g2012 -s tb -o fixed_simv fixed.v tb.v && vvp fixed_simv'
iverilog -g2012 -s tb -o fixed_simv fixed.v tb.v 2>&1 && vvp fixed_simv 2>&1
fixed_status=$?
echo "exit_status=$fixed_status"

if [ "$broken_status" -eq 0 ] || [ "$fixed_status" -ne 0 ]; then
    exit 1
fi
