#!/usr/bin/env bash
# 实验 2：qcow2 扩容/缩容、内部快照增删查、convert -c 压缩前后体积对比。
# 对应教程：https://geek-doc.cn/soc-qemu/qcow2-resize-compress-snapshot.html

source "$(dirname "$0")/common.sh"

WORK="$SCRIPT_DIR/output/02"
mkdir -p "$WORK"
cd "$WORK"

echo "===== 1. 建 32MiB qcow2，写入 8MiB 数据看真实占用增长 ====="
run "$QEMU_IMG" create -f qcow2 disk.qcow2 32M
run "$QEMU_IO" -c 'write -P 0x55 0 8M' disk.qcow2
run du -h disk.qcow2
run "$QEMU_IMG" info disk.qcow2

echo
echo "===== 2. 扩容 +16MiB 到 48MiB，再缩容 -8MiB 回到 40MiB ====="
run "$QEMU_IMG" resize disk.qcow2 +16M
run "$QEMU_IMG" info disk.qcow2
run "$QEMU_IMG" resize --shrink disk.qcow2 -8M
run "$QEMU_IMG" info disk.qcow2

echo
echo "===== 3. 内部快照：打两个快照点、列出、删除第一个 ====="
run "$QEMU_IMG" snapshot -c snap1 disk.qcow2
run "$QEMU_IO" -c 'write -P 0xAA 8M 4M' disk.qcow2
run "$QEMU_IMG" snapshot -c snap2 disk.qcow2
run "$QEMU_IMG" snapshot -l disk.qcow2
run "$QEMU_IMG" snapshot -d snap1 disk.qcow2
run "$QEMU_IMG" snapshot -l disk.qcow2

echo
echo "===== 4. 压缩：24MiB 高重复数据，普通转换 vs convert -c ====="
run "$QEMU_IMG" create -f qcow2 src.qcow2 32M
run "$QEMU_IO" -c 'write -P 0x55 0 24M' src.qcow2
run "$QEMU_IMG" convert -O qcow2 src.qcow2 plain.qcow2
run "$QEMU_IMG" convert -c -O qcow2 src.qcow2 compressed.qcow2
run du -h src.qcow2 plain.qcow2 compressed.qcow2
run "$QEMU_IMG" info compressed.qcow2

echo
echo "实验 2 完成：产物在 output/02/（已 gitignore，可随时重跑生成）"
