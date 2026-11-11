#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.3-sta"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 OpenSTA 2.0.17）" >&2
  exit 2
fi
run() { docker run --rm -v "$PWD:/work" -w /work "$IMAGE" sta -exit -no_init -no_splash "$@" 2>&1; }
printf -- "--- 1. SPEF 层级名与网表不匹配（u_bufx 实例不存在）---\n$ sta bad.tcl\n"
run bad.tcl
printf -- "\n--- 2. 修复：SPEF 连接引脚改回真实层级，read_spef 零告警 ---\n$ sta good.tcl\n"
run good.tcl
printf -- "\n--- 3. report_net 核对 n1 连接 ---\n$ sta net.tcl\n"
run net.tcl
