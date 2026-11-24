#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.5-asic"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 OpenROAD 26Q4）" >&2
  exit 2
fi
run() { docker run --rm -v "$PWD:/work" -w /work "$IMAGE" openroad -exit -no_init "$@" 2>&1; }

printf -- "--- 1. 声明 ss/ff/tt 却漏读 ff：link_design 报 STA-1112，退出 1 ---\n$ openroad -exit bad.tcl\n"
run bad.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 2. 补齐 ff：三个场景分别报告 0.1000/0.0100/0.0500ns，退出 0 ---\n$ openroad -exit good.tcl\n"
run good.tcl
printf -- "RC=%s\n" "$?"
