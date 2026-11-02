#!/usr/bin/env bash
# 一键复现：在 geek-eda:0.3-sta 容器里走完整 Verilator --cc 链路
# 用法：./run.sh
set -euo pipefail
IMAGE=geek-eda:0.3-sta
docker run --rm -v "$PWD":/work -w /work "$IMAGE" bash run-native.sh
