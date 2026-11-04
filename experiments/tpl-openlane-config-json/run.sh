#!/bin/bash
# Clean reference full flow: sky130A RTL -> GDS with the minimal config.json template.
set -u
B="$(cd "$(dirname "$0")/../.." && pwd)"
D=$B/tpl-openlane-config-json
cd "$D"
sudo rm -rf runs
$B/olrun.sh "$D" -tag baseline -overwrite | tee baseline.console.log
echo "key reports:"
ls runs/baseline/reports/synthesis/*stat.rpt runs/baseline/reports/manufacturability.rpt
