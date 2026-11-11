#!/usr/bin/env bash
# 一键复现：在 geek-eda:0.3-sta 容器里跑完整断言实验
set -euo pipefail
IMAGE=geek-eda:0.3-sta
docker run --rm -v "$PWD":/work -w /work "$IMAGE" bash run-native.sh
