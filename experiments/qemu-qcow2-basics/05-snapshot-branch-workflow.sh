#!/usr/bin/env bash
# 实验 5：在同一 qcow2 中保存基线与两条实验分支，切换、验证并演示删除边界。
# 对应教程：https://geek-doc.cn/soc-qemu/qcow2-snapshot-branch-workflow.html

source "$(dirname "$0")/common.sh"

WORK="$SCRIPT_DIR/output/05"
rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

run "$QEMU_IMG" create -f qcow2 lab.qcow2 16M
run "$QEMU_IO" -c 'write -P 0x11 0 1M' lab.qcow2
run "$QEMU_IMG" snapshot -c baseline lab.qcow2

echo
echo "===== 分支 A：从基线写入 0xAA ====="
run "$QEMU_IO" -c 'write -P 0xAA 1M 1M' lab.qcow2
run "$QEMU_IMG" snapshot -c branch-a lab.qcow2
run "$QEMU_IO" -c 'read -P 0xAA 1M 64K' lab.qcow2

echo
echo "===== 回到基线，再建立分支 B ====="
run "$QEMU_IMG" snapshot -a baseline lab.qcow2
run "$QEMU_IO" -c 'read -P 0x11 0 64K' lab.qcow2
run "$QEMU_IO" -c 'read -P 0x00 1M 64K' lab.qcow2
run "$QEMU_IO" -c 'write -P 0xBB 2M 1M' lab.qcow2
run "$QEMU_IMG" snapshot -c branch-b lab.qcow2
run "$QEMU_IMG" snapshot -l lab.qcow2

echo
echo "===== 切到 A：A 数据在，B 数据不在 ====="
run "$QEMU_IMG" snapshot -a branch-a lab.qcow2
run "$QEMU_IO" -c 'read -P 0xAA 1M 64K' lab.qcow2
run "$QEMU_IO" -c 'read -P 0x00 2M 64K' lab.qcow2

echo
echo "===== 切到 B：B 数据在，A 数据不在 ====="
run "$QEMU_IMG" snapshot -a branch-b lab.qcow2
run "$QEMU_IO" -c 'read -P 0xBB 2M 64K' lab.qcow2
run "$QEMU_IO" -c 'read -P 0x00 1M 64K' lab.qcow2

echo
echo "===== 删除 A 后不能再次应用，当前 B 状态不受影响 ====="
run "$QEMU_IMG" snapshot -d branch-a lab.qcow2
run "$QEMU_IMG" snapshot -l lab.qcow2
echo "+ $QEMU_IMG snapshot -a branch-a lab.qcow2"
set +e
"$QEMU_IMG" snapshot -a branch-a lab.qcow2
rc=$?
set -e
echo "(exit code: $rc)"
if [ "$rc" -eq 0 ]; then
  echo "FATAL: deleted snapshot branch-a unexpectedly applied" >&2
  exit 1
fi
run "$QEMU_IO" -c 'read -P 0xBB 2M 64K' lab.qcow2

echo
echo "RESULT: PASS (baseline, branch switching, isolation, deletion boundary)"
