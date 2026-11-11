#!/usr/bin/env bash
# Reproduce the first cocotb test run inside the geek-eda container.
set -euo pipefail
{
  echo "# command: make sim=icarus (in experiments/flow-cocotb-first-test)"
  echo "# date: 2026-11-03"
  echo "# host-toolchain: cocotb 2.1.0 + Icarus Verilog 12.0 (geek-eda:0.3-sta docker), Python 3.12"
  make sim=icarus
  echo "# --- results.xml (hostname attribute stripped) ---"
  sed 's/ hostname="[^"]*"//' results.xml
} 2>&1
