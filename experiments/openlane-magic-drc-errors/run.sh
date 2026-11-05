#!/usr/bin/env bash
# Magic 独立 DRC 好坏对照：同一版图结构，met1 间距 0.03um（违例）vs 0.20um（干净）
# 在装有 OpenLANE d054702b 镜像与 sky130A PDK 的机器上执行：./run.sh
set -u
PDKR="${PDKR:-$HOME/.volare}"
OLIMG="${OLIMG:-$(sudo docker images --format '{{.Repository}}:{{.Tag}}' | grep -m1 openlane)}"
RCFILE="$PDKR/sky130A/libs.tech/openlane/magic/sky130A.magicrc"

for case in bad good; do
  echo "== DRC $case =="
  sudo docker run --rm -v "$PWD:/work" -w /work/tcl \
    -v "$PDKR:$PDKR" -e PDK_ROOT="$PDKR" -e PDK=sky130A \
    "$OLIMG" magic -dnull -noconsole -rcfile "$RCFILE" "drc-$case.tcl"
done
