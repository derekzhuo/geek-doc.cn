#!/bin/bash
# PDK name / PDK_ROOT mismatch signatures in OpenLane 2023.07.19.
set -u
B="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG=openlane-pdk-version-mismatch
D=$B/$SLUG
IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -m1 'efabless/openlane')
COMMON="docker run --rm -v /opt/openlane-src/OpenLane:/openlane -v $HOME/.volare:$HOME/.volare -v $D:/designs/lab -w /openlane -e PWD=/openlane $IMAGE"
cd "$D"

echo "== CASE A: PDK=sky130C (a PDK flavour volare has not installed) =="
sudo rm -rf runs
$COMMON -e PDK_ROOT=$HOME/.volare -e PDK=sky130C \
  ./flow.tcl -design /designs/lab -tag badpdk -overwrite | tee c3a.log || true

echo "== CASE B: PDK_ROOT points at an empty directory =="
mkdir -p $B/empty-pdk
docker run --rm -v /opt/openlane-src/OpenLane:/openlane -v $HOME/.volare:$HOME/.volare \
  -v $B/empty-pdk:/wrongpdk -v $D:/designs/lab -w /openlane \
  -e PDK_ROOT=/wrongpdk -e PDK=sky130A -e PWD=/openlane $IMAGE \
  ./flow.tcl -design /designs/lab -tag badroot -overwrite | tee c3b.log || true

echo "== CASE C (fixed): correct PDK_ROOT/PDK, run synthesis interactively =="
sudo rm -rf runs
printf 'run_synthesis\nexit\n' | $B/olrun-i.sh "$D" -tag pdk_ok -interactive | tee c3-good.log
