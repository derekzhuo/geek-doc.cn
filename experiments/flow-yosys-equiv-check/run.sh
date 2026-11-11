#!/bin/bash
# 一键复现：在 geek-eda:0.4-flow 容器中跑 Yosys 组合等价检查
# 用法：bash run.sh
echo "# command: bash run.sh (docker geek-eda:0.4-flow yosys -s eq.ys / neq.ys)"
echo "# date: 2026-11-04"
echo "# host-toolchain: Yosys 0.33 (geek-eda:0.4-flow docker)"

echo "==== yosys -V ===="
docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow yosys -V

echo "==== case 1: golden vs revised (expect EQUIVALENT) ===="
docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow yosys -s eq.ys
echo "case1 exit code: $?"

echo "==== case 2: golden vs buggy (expect NOT EQUIVALENT) ===="
docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow yosys -s neq.ys
echo "case2 exit code: $?"
