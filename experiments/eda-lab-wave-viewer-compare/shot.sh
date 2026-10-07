#!/bin/sh
# shot.sh —— 无头环境给 GTKWave 截一张真实 PNG
# 原理：Xvfb 起虚拟显示器 → gtkwave 加载 VCD + savefile，
#       Tcl 脚本把窗口拉回 0 起点并缩放到全景 → ImageMagick import 抓全屏。
# 注意：gtkwave::setZoomFactor 是 2 的幂次语义，负值拉宽；
#       本 VCD 全程 286 ns，-18 时整段波形正好铺满窗口（实测校准值）。
set -e
mkdir -p out

cat > /tmp/zoom.tcl <<'EOF'
gtkwave::setWindowStartTime 0
gtkwave::setZoomFactor -18
EOF

Xvfb :99 -screen 0 1280x800x24 &
XPID=$!
sleep 2

DISPLAY=:99 gtkwave counter.vcd signals.gtkw -S /tmp/zoom.tcl &
GPID=$!
sleep 12

DISPLAY=:99 import -window root out/gtkwave.png

kill $GPID 2>/dev/null || true
kill $XPID 2>/dev/null || true
ls -l out/gtkwave.png
