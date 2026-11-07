#!/usr/bin/env bash
# 实验 4：同一份 qcow2 镜像转成 vmdk/vdi/raw，对照四种格式的真实占用与 info 字段。
# 对应教程：https://geek-doc.cn/soc-qemu/qcow2-raw-vmdk-formats.html

source "$(dirname "$0")/common.sh"

WORK="$SCRIPT_DIR/output/04"
mkdir -p "$WORK"
cd "$WORK"

echo "===== 1. 建 64MiB qcow2 并写入 8MiB 数据，作为统一转换源 ====="
run "$QEMU_IMG" create -f qcow2 base.qcow2 64M
run "$QEMU_IO" -c 'write -P 0x55 0 8M' base.qcow2

echo
echo "===== 2. 同一数据源分别转成 vmdk、vdi、raw ====="
run "$QEMU_IMG" convert -O vmdk base.qcow2 disk.vmdk
run "$QEMU_IMG" convert -O vdi base.qcow2 disk.vdi
run "$QEMU_IMG" convert -O raw base.qcow2 disk.raw

echo
echo "===== 3. 四种格式逐个 info，对照 virtual size 与 disk size ====="
for f in base.qcow2 disk.vmdk disk.vdi disk.raw; do
  echo "--- $f ---"
  run du -h "$f"
  run "$QEMU_IMG" info "$f"
done

echo
echo "实验 4 完成：产物在 output/04/（已 gitignore，可随时重跑生成）"
