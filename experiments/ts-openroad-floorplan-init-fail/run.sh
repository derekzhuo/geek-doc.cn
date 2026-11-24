#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.5-asic"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 OpenROAD 26Q4）" >&2
  exit 2
fi
run() { docker run --rm -v "$PWD:/work" -w /work "$IMAGE" openroad -exit -no_init "$@" 2>&1; }

printf -- "--- 1. 失败：core 0.5x0.5um 放不下 0.68x1.0um 的 invx1 ---\n$ openroad -exit bad.tcl\n"
run bad.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 2. 边界：core 1.0x1.0um，按 SITE 网格对齐后利用率恰为 100%%，仍通过 ---\n$ openroad -exit mid.tcl\n"
run mid.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 3. 宽松：core 20x20um，利用率 0.002，report_design_area 正常 ---\n$ openroad -exit good.tcl\n"
run good.tcl
printf -- "RC=%s\n" "$?"
