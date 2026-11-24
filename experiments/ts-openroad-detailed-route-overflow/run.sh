#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.5-asic"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 OpenROAD 26Q4）" >&2
  exit 2
fi
run() { docker run --rm -v "$PWD:/work" -w /work "$IMAGE" openroad -exit -no_init "$@" 2>&1; }
rm -f -- bad-iter.guide bad-layer.guide good.guide bad-iter.drc.rpt bad-layer.drc.rpt good.drc.rpt

printf -- "--- 1. 同样三层资源，但详细布线只跑 2 轮：残留 DRC，退出码仍为 0 ---\n$ openroad -exit bad.tcl\n"
run bad.tcl
printf -- "RC=%s\nDRC violations=" "$?"
grep -c '^violation type:' bad-iter.drc.rpt || true

printf -- "\n--- 2. 只允许 metal1：全局布线拥塞，详细布线找不到时钟 pin 接入点 ---\n$ openroad -exit bad-layer.tcl\n"
run bad-layer.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 3. 三层资源并允许 10 轮：违例从 13 降到 0 ---\n$ openroad -exit good.tcl\n"
run good.tcl
printf -- "RC=%s\nDRC violations=" "$?"
grep -c '^violation type:' good.drc.rpt || true
