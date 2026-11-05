#!/usr/bin/env bash
# docker bind mount 路径三对照：Windows 盘符路径在 Linux Docker 下的两种误写与正确写法
# 在任意 Linux（含 WSL2）docker 主机上直接执行：./run.sh
set -u
IMG="${IMG:-alpine:latest}"

echo "## case1: Windows 反斜杠盘符路径直接喂给 Linux Docker"
docker run --rm -v 'C:\Users\dev\proj:/data' "$IMG" echo mount-ok
echo "## case1 exit: $?"

echo "## case2: 正斜杠盘符路径（WSL 内常见误写）"
docker run --rm -v 'C:/Users/dev/proj:/data' "$IMG" echo mount-ok
echo "## case2 exit: $?"

echo "## case3: 正确的 WSL 挂载路径 /mnt/c/..."
HOSTDIR="${HOSTDIR:-/tmp/wsl-mount-demo}"
mkdir -p "$HOSTDIR"
docker run --rm -v "$HOSTDIR:/data" "$IMG" sh -c 'echo mount-ok; ls -ld /data'
echo "## case3 exit: $?"
