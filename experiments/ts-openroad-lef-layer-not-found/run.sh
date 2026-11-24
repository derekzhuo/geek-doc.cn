#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
IMAGE="geek-eda:0.5-asic"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "需要本地 Docker 镜像 $IMAGE（含 OpenROAD 26Q4）" >&2
  exit 2
fi
run() { docker run --rm -v "$PWD:/work" -w /work "$IMAGE" openroad -exit -no_init "$@" 2>&1; }

printf -- "--- 1. 错误顺序：先读 macro.lef（metal1 尚未由 tech LEF 定义）---\n$ openroad -exit bad.tcl\n"
run bad.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 2. 正确顺序：先 tech.lef 再 macro.lef，零告警 ---\n$ openroad -exit good.tcl\n"
run good.tcl
printf -- "RC=%s\n" "$?"

printf -- "\n--- 3. 坏顺序回写探针：PIN 的 PORT/RECT 几何被静默剥除 ---\n$ openroad -exit probe-bad.tcl; grep -cE '^[[:space:]]+RECT[[:space:]]' roundtrip-bad.lef\n"
run probe-bad.tcl >/dev/null 2>&1
printf "roundtrip-bad.lef 中 PIN 几何 RECT 行数: "
grep -cE '^[[:space:]]+RECT[[:space:]]' roundtrip-bad.lef || true
sed -n '/MACRO invx1/,/END invx1/p' roundtrip-bad.lef

printf -- "\n--- 4. 好顺序回写探针：库 LEF（_1 后缀）保留完整 PORT/RECT ---\n$ openroad -exit probe-good.tcl; grep -cE '^[[:space:]]+RECT[[:space:]]' roundtrip-good_1.lef\n"
run probe-good.tcl >/dev/null 2>&1
printf "roundtrip-good_1.lef 中 PIN 几何 RECT 行数: "
grep -cE '^[[:space:]]+RECT[[:space:]]' roundtrip-good_1.lef || true
sed -n '/MACRO invx1/,/END invx1/p' roundtrip-good_1.lef

rm -f roundtrip-bad.lef roundtrip-good.lef roundtrip-good_1.lef
