#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.5-asic"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 OpenROAD 26Q4）" >&2
  exit 2
fi
run() { docker run --rm -v "$PWD:/work" -w /work "$IMAGE" openroad -exit -no_init "$@" 2>&1; }

printf -- "--- 1. 未定义 corner：STA-0102，退出 1 ---\n$ openroad -exit bad-undefined.tcl\n"
run bad-undefined.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 2. 同一文件重复读入 ss：STA-1140 警告，退出 0，集合同名单元出现两次 ---\n$ openroad -exit bad-duplicate-same.tcl\n"
run bad-duplicate-same.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 3. ff/ss 两份不同库都读入 ss：无报错，两个库单元同时存在，退出 0 ---\n$ openroad -exit bad-duplicate.tcl\n"
run bad-duplicate.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 4. 正确映射：ss 使用 0.10ns 库，ff 使用 0.01ns 库 ---\n$ openroad -exit good.tcl\n"
run good.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 5. ss/ff 库接反：仍退出 0，但两个场景的路径延迟对调 ---\n$ openroad -exit swapped.tcl\n"
run swapped.tcl
printf -- "RC=%s\n" "$?"
