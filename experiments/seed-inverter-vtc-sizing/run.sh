#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p data
for wp in 0.5 1 2 4; do
  sed "s/@WP@/${wp}/g" cir/inverter.cir.in > "data/inverter_wp_${wp}.cir"
  ngspice -b "data/inverter_wp_${wp}.cir" > "data/ngspice_wp_${wp}.log" 2>&1
done
python3 analyze.py data results.csv summary.json
cat summary.json
python3 verify.py data results.csv
