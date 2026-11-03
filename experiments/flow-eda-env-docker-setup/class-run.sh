#!/usr/bin/env bash
# 本班实测：用本机已有的版本固定镜像 geek-eda:0.3-sta 验证
# 「docker run --rm -v $PWD:/work -w /work」整条环境搭建流程。
# 读者可复现的等价做法是用同目录 Dockerfile 自行 build（见 run.sh）。
set -euo pipefail
IMG=geek-eda:0.3-sta

echo "==== [1] host docker ===="
docker --version

echo "==== [2] image tag is fixed, image id never changes ===="
docker images "$IMG" --format 'repo={{.Repository}} tag={{.Tag}} id={{.ID}} size={{.Size}}'

echo "==== [3] one ephemeral container per tool, print version ===="
docker run --rm "$IMG" sh -c 'iverilog -V 2>/dev/null | head -1'
docker run --rm "$IMG" sh -c 'vvp -V 2>/dev/null | head -1'
docker run --rm "$IMG" verilator --version
docker run --rm "$IMG" yosys -V
docker run --rm "$IMG" sh -c 'sta -version 2>/dev/null | head -1'

echo "==== [4] mount current dir, compile and simulate in container ===="
cd demo
rm -f sim.vvp
docker run --rm -v "$PWD":/work -w /work "$IMG" \
    sh -c 'pwd && ls && iverilog -o sim.vvp design.v tb_add2.v && vvp sim.vvp'

echo "==== [5] artifact written back to host working dir ===="
wc -c sim.vvp

echo "==== [6] --rm leaves no stopped container behind ===="
docker ps -a --filter ancestor="$IMG" --format 'left={{.ID}} {{.Status}}'
echo "(empty list above means nothing left)"

echo "==== [7] same tag later: versions still pinned ===="
docker run --rm "$IMG" sh -c 'iverilog -V 2>/dev/null | head -1'
