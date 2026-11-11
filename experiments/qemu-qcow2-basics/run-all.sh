#!/usr/bin/env bash
# 依次跑三个实验，完整输出可直接 tee 到日志：./run-all.sh | tee run1.log
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/01-create-info-convert.sh"
echo
"$DIR/02-resize-snapshot-compress.sh"
echo
"$DIR/03-backing-file-clone.sh"
echo
"$DIR/04-formats-compare.sh"
