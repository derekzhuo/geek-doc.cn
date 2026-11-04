#!/bin/bash
# PL_TARGET_DENSITY out-of-range signature in OpenLane 2023.07.19 / OpenROAD gpl.
set -u
B="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG=openlane-pl-target-density
D=$B/$SLUG
cd "$D"

echo "== CASE A: PL_TARGET_DENSITY=1.5 (>1) -> OpenROAD GPL-0135 at global placement =="
python3 - <<'PY'
import json
c=json.load(open("configs/config.base.json"))
c["PL_TARGET_DENSITY"]=1.5
json.dump(c,open("config.json","w"),indent=2)
PY
sudo rm -rf runs
$B/olrun.sh "$D" -tag dens_bad -overwrite | tee c4-bad.log || true

echo "== CASE B (fixed): PL_TARGET_DENSITY=0.5 -> interactive through run_placement =="
cp configs/config.base.json config.json
sudo rm -rf runs
printf 'run_synthesis\nrun_floorplan\nrun_placement\nexit\n' | $B/olrun-i.sh "$D" -tag dens_ok -interactive | tee c4-good.log
