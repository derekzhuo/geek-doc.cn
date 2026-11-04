#!/bin/bash
# Reproduce: unknown/misspelled config key in OpenLane 2023.07.19 (sky130A container).
# Layout on CVM: ~/eda-errlog-b/<this dir> with olrun.sh / olrun-i.sh one level up.
set -u
B="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG=openlane-config-key-unknown
D=$B/$SLUG
cd "$D"

echo "== CASE A: VERILOG_FIELS typo (unknown key silently accepted; failure surfaces at step 0) =="
cp configs/config.bad.json config.json
sudo rm -rf runs
$B/olrun.sh "$D" -tag bad_key -overwrite | tee c1-bad.log || true

echo "== CASE B: key fixed to VERILOG_FILES; run synthesis interactively =="
cp configs/config.good.json config.json
sudo rm -rf runs
printf 'run_synthesis\nexit\n' | $B/olrun-i.sh "$D" -tag fixed_key -interactive | tee c1-good.log
