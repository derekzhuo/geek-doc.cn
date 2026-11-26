#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build results

set -x
date -u '+DATE_UTC=%Y-%m-%dT%H:%M:%SZ'
uname -srm
sw_vers
iverilog -V
vvp -V
python3 --version
python3 gen_vectors.py

iverilog -g2012 -DINJECT_SUB_CARRY -s alu4_tb -o .build/alu4_broken.vvp alu4.v alu4_tb.v
set +e
vvp .build/alu4_broken.vvp 2>&1 | tee results/broken.log
broken_rc=${PIPESTATUS[0]}
set -e
printf 'BROKEN_EXIT=%d (nonzero required)\n' "$broken_rc"
if [[ "$broken_rc" -eq 0 ]]; then
    printf 'ERROR fault injection escaped detection\n' >&2
    exit 1
fi
grep -F 'MISMATCH index=256 op=1 A=0 B=0 expected R=0 NZCV=0110 actual R=0 NZCV=0100' results/broken.log
grep -F 'SUMMARY vectors=1280 failures=256' results/broken.log

iverilog -g2012 -s alu4_tb -o .build/alu4_good.vvp alu4.v alu4_tb.v
vvp .build/alu4_good.vvp 2>&1 | tee results/correct.log
grep -F 'PASS vectors=1280 failures=0' results/correct.log

iverilog -g2012 -s wave_tb -o .build/wave.vvp alu4.v wave_tb.v
vvp .build/wave.vvp 2>&1 | tee results/wave.log
grep -F 'WAVE PASS vectors=6 failures=0' results/wave.log
printf 'RUN PASS: injected fault detected (256 failures), corrected RTL passed 1280/1280, selected waveform passed 6/6\n'
