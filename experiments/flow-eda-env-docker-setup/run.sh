#!/usr/bin/env bash
# 读者可复现：构建最小开源 EDA 镜像并在容器里跑通一次挂载编译
set -euo pipefail

echo "==== [1] host docker version ===="
docker --version

echo "==== [2] build image flow-eda-mini:0.1 ===="
docker build -t flow-eda-mini:0.1 .

echo "==== [3] tool version inside container ===="
docker run --rm flow-eda-mini:0.1 iverilog -V | head -3
docker run --rm flow-eda-mini:0.1 vvp -V | head -1

echo "==== [4] mount demo dir, compile and run ===="
cd demo
docker run --rm -v "$PWD":/work -w /work flow-eda-mini:0.1 \
    sh -c 'pwd && ls && iverilog -o sim.vvp design.v tb_add2.v && vvp sim.vvp'

echo "==== [5] artifacts written back to host dir ===="
ls -l sim.vvp

echo "==== [6] same image tag is immutable: run again, versions stay identical ===="
docker run --rm flow-eda-mini:0.1 iverilog -V | head -1
