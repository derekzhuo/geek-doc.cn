#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.5-asic"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 OpenROAD 26Q4）" >&2
  exit 2
fi
run() { docker run --rm -v "$PWD:/work" -w /work "$IMAGE" openroad -exit -no_init "$@" 2>&1; }

printf -- "--- 1. Liberty 没有 buffer：RSZ-0110，退出 1 ---\n$ openroad -exit bad-auto.tcl\n"
run bad-auto.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 2. 指定不存在的 buffer 主单元：CTS-0126，退出 1 ---\n$ openroad -exit bad-list.tcl\n"
run bad-list.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 3. buffer 有 LEF/Liberty 但缺 max_transition：CTS-0107，退出 1 ---\n$ openroad -exit bad-slew.tcl\n"
run bad-slew.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 4. 提供完整 BUF_X1 并显式指定：CTS 插入 3 个 buffer，skew 报告正常 ---\n$ openroad -exit good.tcl\n"
run good.tcl
printf -- "RC=%s\n" "$?"
