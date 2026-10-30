#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' '# command: bash run.sh'
printf '%s\n' '# date: 2026-10-31'
printf '%s\n' '# host-toolchain: Docker geek-eda:0.2 / Verilator 5.020 2024-01-01'

verilator --version
verilator --binary --assert --timing -Wall -Wno-fatal \
  --top-module tb_sva_templates tb_sva_templates.sv

echo "=== normal run: all properties must hold ==="
./obj_dir/Vtb_sva_templates

echo "=== injected-fault run: every property must report its violation ==="
./obj_dir/Vtb_sva_templates +INJECT_FAULTS
