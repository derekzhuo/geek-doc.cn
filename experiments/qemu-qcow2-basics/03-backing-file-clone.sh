#!/usr/bin/env bash
# 实验 3：backing file 增量链——base 模板 + 两个 overlay 克隆、写隔离验证、断链复现与 rebase 修复。
# 对应教程：https://geek-doc.cn/soc-qemu/qcow2-backing-file-clone.html

source "$(dirname "$0")/common.sh"

WORK="$SCRIPT_DIR/output/03"
mkdir -p "$WORK"
cd "$WORK"

echo "===== 1. 建 64MiB 基础镜像 base.qcow2，在 8MiB 偏移写入 4MiB 模板数据 ====="
run "$QEMU_IMG" create -f qcow2 base.qcow2 64M
run "$QEMU_IO" -c 'write -P 0x55 8M 4M' base.qcow2
run du -h base.qcow2

echo
echo "===== 2. 基于 base 建两个 overlay（秒级克隆两台虚拟机）====="
run "$QEMU_IMG" create -f qcow2 -b base.qcow2 -F qcow2 vm1.qcow2
run "$QEMU_IMG" create -f qcow2 -b base.qcow2 -F qcow2 vm2.qcow2
run "$QEMU_IMG" info vm1.qcow2
run du -h base.qcow2 vm1.qcow2 vm2.qcow2

echo
echo "===== 3. 写隔离：只在 vm1 头部写 4MiB，base 与 vm2 均不受影响 ====="
run "$QEMU_IO" -c 'write -P 0xAB 0 4M' vm1.qcow2
echo "-- vm1 头部读到 0xAB（本层写入）--"
run "$QEMU_IO" -c 'read -P 0xAB 0 64k' vm1.qcow2
echo "-- base 头部仍是 0（未被 overlay 写穿）--"
run "$QEMU_IO" -c 'read -P 0x00 0 64k' base.qcow2
echo "-- vm2 头部同样读 0（两个 overlay 互相独立）--"
run "$QEMU_IO" -c 'read -P 0x00 0 64k' vm2.qcow2
echo "-- vm1 在 8MiB 处仍能透过链读到 base 的 0x55 模板数据 --"
run "$QEMU_IO" -c 'read -P 0x55 8M 64k' vm1.qcow2
run du -h base.qcow2 vm1.qcow2 vm2.qcow2

echo
echo "===== 4. 断链复现：改名 base 后 info 仍能读元数据，但 check 与实际读写立即失败 ====="
run mv base.qcow2 base-renamed.qcow2
run "$QEMU_IMG" info vm1.qcow2
run_may_fail "$QEMU_IMG" check vm1.qcow2
run_may_fail "$QEMU_IO" -c 'read -P 0x55 8M 64k' vm1.qcow2

echo
echo "===== 5. rebase -u 只改元数据指针，修复指向新文件名 ====="
run "$QEMU_IMG" rebase -u -b base-renamed.qcow2 -F qcow2 vm1.qcow2
run "$QEMU_IMG" rebase -u -b base-renamed.qcow2 -F qcow2 vm2.qcow2
run "$QEMU_IMG" info vm1.qcow2
echo "-- 修复后链上读取恢复正常 --"
run "$QEMU_IO" -c 'read -P 0x55 8M 64k' vm1.qcow2

echo
echo "实验 3 完成：产物在 output/03/（已 gitignore，可随时重跑生成）"
