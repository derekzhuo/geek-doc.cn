#!/usr/bin/env bash
set -euo pipefail

mkdir -p results
printf '%s\n' '$ ngspice --version'
ngspice --version
printf '%s\n' '$ ngspice rc_sweep.cir'
ngspice rc_sweep.cir 2>&1 | tee results/ngspice.log
printf '%s\n' '$ awk -f verify.awk results/ngspice.log'
awk -f verify.awk results/ngspice.log
printf '%s\n' '$ wc -l results/ac_1k results/ac_2.2k results/ac_4.7k'
wc -l results/ac_1k results/ac_2.2k results/ac_4.7k
