#!/usr/bin/env bash
# qcow2 镜像打不开的三类故障真复现：
#   1) 镜像头被截断（truncate）：qcow2 header too short，check 同样无法打开，只能靠备份恢复；
#   2) raw 内容伪装成 qcow2（错误指定 -f qcow2）：Image is not in qcow2 format，
#      去掉 -f 让 qemu-img 自动探测，扩展名不决定格式；
#   3) 权限 000：Permission denied，改回可读权限即恢复。
# 每个故障段都打印退出码，并在同段给出修复验证。
set -uo pipefail
cd "$(dirname "$0")"
rm -rf build
mkdir -p build
cd build

echo '$ bash run.sh'
echo "== 0. 工具版本 =="
qemu-img --version | head -1
echo

echo "== 1. 准备健康基线镜像 base.qcow2（64 MiB）=="
qemu-img create -f qcow2 base.qcow2 64M
qemu-img info base.qcow2 | head -4
cp base.qcow2 base.backup.qcow2
echo

echo "== 2. 故障一：镜像头截断到 64 字节 =="
cp base.qcow2 trunc.qcow2
truncate -s 64 trunc.qcow2
ls -l trunc.qcow2
echo "-- qemu-img info（预期失败）--"
qemu-img info trunc.qcow2
echo "exit=$?"
echo "-- qemu-img check（同样打不开，check 不是头损坏的修复手段）--"
qemu-img check trunc.qcow2
echo "exit=$?"
echo "-- 修复：从备份恢复后 info 正常 --"
cp base.backup.qcow2 trunc.qcow2
qemu-img info trunc.qcow2 | head -3
echo

echo "== 3. 故障二：raw 内容起 .qcow2 名字，却按 qcow2 打开 =="
qemu-img create -f raw fake-as-qcow2.qcow2 16M
echo "-- 显式 -f qcow2 打开（预期失败）--"
qemu-img info -f qcow2 fake-as-qcow2.qcow2
echo "exit=$?"
echo "-- 不带 -f 自动探测：内容是 raw，与扩展名无关 --"
qemu-img info fake-as-qcow2.qcow2 | head -3
echo "exit=$?"
echo "-- 修复：按真实格式 raw 打开 --"
qemu-img info -f raw fake-as-qcow2.qcow2 | head -3
echo

echo "== 4. 故障三：权限位 000 =="
cp base.qcow2 noperm.qcow2
chmod 000 noperm.qcow2
ls -l noperm.qcow2
echo "-- qemu-img info（预期失败）--"
qemu-img info noperm.qcow2
echo "exit=$?"
echo "-- 修复：所有者改回 600 --"
chmod 600 noperm.qcow2
qemu-img info noperm.qcow2 | head -3
echo

echo "== 5. 健康镜像的 check 基线输出 =="
qemu-img check base.qcow2
echo "exit=$?"
echo "done"
