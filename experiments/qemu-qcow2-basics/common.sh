#!/usr/bin/env bash
# 三个实验脚本共用：工具探测、产物目录、命令回显。
# 每条执行的命令都以 "+ <命令行>" 原样回显，便于教程里的终端卡与日志逐行对上。

set -euo pipefail

QEMU_IMG="$(command -v qemu-img)"
QEMU_IO="$(command -v qemu-io)"

if [ -z "$QEMU_IMG" ] || [ -z "$QEMU_IO" ]; then
  echo "FATAL: 需要 qemu-img 与 qemu-io（QEMU utils），请先安装 QEMU" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
  echo "+ $*"
  "$@"
}

# 允许失败的命令（用于真实复现报错），同样回显命令行并打印返回码。
run_may_fail() {
  echo "+ $*"
  set +e
  "$@"
  local rc=$?
  set -e
  echo "(exit code: $rc)"
  return 0
}
