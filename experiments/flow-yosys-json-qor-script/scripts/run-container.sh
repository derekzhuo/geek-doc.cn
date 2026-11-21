#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf build
mkdir -p build
printf '%s\n' '== tool versions =='
yosys -V
python3 --version
printf '%s\n' '== export and analyze three designs =='
for design in arbiter4 counter8 hier_alu; do
    printf '\n== %s ==\n' "$design"
    yosys -l "build/${design}.yosys.log" -p \
      "read_verilog -sv rtl/arbiter4.v rtl/counter8.v rtl/hier_alu.v; hierarchy -check -top ${design}; proc; opt; stat; tee -o build/${design}.stat.json stat -json; write_json build/${design}.json"
    python3 scripts/qor.py --json "build/${design}.json" \
      --stat-json "build/${design}.stat.json" --top "$design" | tee "build/${design}.qor.log"
done
printf '\n== final result: all direct JSON/stat comparisons passed ==\n'
