#!/bin/bash
# Resume/tag failure signatures in OpenLane 2023.07.19 (sky130A container).
set -u
B="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG=openlane-resume-from-tag
D=$B/$SLUG
cd "$D"

echo "== CASE A: legacy -from flag (removed since this release) =="
$B/olrun.sh "$D" -tag x -from floorplan | tee c2a.log || true

echo "== CASE B: fresh tag 'ghost', jump straight to run_floorplan (no synthesis state) =="
sudo rm -rf runs
printf 'run_floorplan\nexit\n' | $B/olrun-i.sh "$D" -tag ghost -interactive | tee c2b.log || true

echo "== CASE C: create tag r1 (synthesis), then prep same tag again without -overwrite =="
sudo rm -rf runs
printf 'run_synthesis\nexit\n' | $B/olrun-i.sh "$D" -tag r1 -interactive > c2c1.log
printf 'run_floorplan\nexit\n' | $B/olrun-i.sh "$D" -tag r1 -interactive | tee c2c2.log || true

echo "== CASE D (correct): single interactive session, steps in order =="
sudo rm -rf runs
printf 'run_synthesis\nrun_floorplan\nexit\n' | $B/olrun-i.sh "$D" -tag r2 -interactive | tee c2-good.log
