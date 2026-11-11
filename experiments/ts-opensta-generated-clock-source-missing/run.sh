#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.3-sta"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 OpenSTA 2.0.17）" >&2
  exit 2
fi
run() { docker run --rm -v "$PWD:/work" -w /work "$IMAGE" sta -exit -no_init -no_splash "$@" 2>&1; }
printf -- "--- 1. create_generated_clock 的 -source 引用不存在的引脚 ---\n$ sta bad.tcl\n"
run bad.tcl
printf -- "\n--- 2. 修复：-source 改为真实时钟端口 clk ---\n$ sta good.tcl\n"
run good.tcl
