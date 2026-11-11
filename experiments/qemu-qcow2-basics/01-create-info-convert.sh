#!/usr/bin/env bash
# 实验 1：创建 raw 与 qcow2 两种镜像，对比虚拟大小与真实占用，再做双向格式转换。
# 对应教程：https://geek-doc.cn/soc-qemu/qemu-img-create-info-convert.html

source "$(dirname "$0")/common.sh"

WORK="$SCRIPT_DIR/output/01"
mkdir -p "$WORK"
cd "$WORK"

echo "===== 1. 各建一个 64MiB 镜像：raw 与 qcow2 ====="
run "$QEMU_IMG" create -f raw disk-raw.img 64M
run "$QEMU_IMG" create -f qcow2 disk.qcow2 64M

echo
echo "===== 2. ls 看表观大小，du 看真实磁盘占用 ====="
run ls -lh disk-raw.img disk.qcow2
run du -h disk-raw.img disk.qcow2

echo
echo "===== 3. qemu-img info 读出虚拟大小与实际占用 ====="
run "$QEMU_IMG" info disk-raw.img
run "$QEMU_IMG" info disk.qcow2

echo
echo "===== 4. qcow2 转 raw（解开稀疏封装）====="
run "$QEMU_IMG" convert -O raw disk.qcow2 from-qcow2.img
run "$QEMU_IMG" info from-qcow2.img

echo
echo "===== 5. raw 转回 qcow2（往返转换，重新稀疏化）====="
run "$QEMU_IMG" convert -O qcow2 disk-raw.img roundtrip.qcow2
run "$QEMU_IMG" info roundtrip.qcow2
run du -h disk-raw.img disk.qcow2 roundtrip.qcow2

echo
echo "实验 1 完成：产物在 output/01/（已 gitignore，可随时重跑生成）"
