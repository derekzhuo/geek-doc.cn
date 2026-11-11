#!/usr/bin/env bash
# 宿主机入口：一条命令录完整对照实验
# 用法：bash run.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
IMG="geek-eda:0.3-sta"

{
  echo "# command: bash run.sh"
  echo "# date: 2026-11-03"
  echo "# host-toolchain: Yosys 0.33 (geek-eda:0.3-sta docker)"
  docker run --rm -v "$DIR":/work -w /work "$IMG" sh record.sh
} 2>&1 | tee "$DIR/run1.log"
