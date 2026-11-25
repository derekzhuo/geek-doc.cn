#!/usr/bin/env bash
set -euo pipefail

rm -rf results
mkdir -p results

echo "# command: bash run.sh"
echo "# date: 2026-11-26"
echo "# command: ngspice --version"
ngspice --version
echo "# command: python3 scripts/run_analysis.py"
python3 scripts/run_analysis.py 2>&1
echo "# command: python3 scripts/validate_results.py"
python3 scripts/validate_results.py 2>&1
