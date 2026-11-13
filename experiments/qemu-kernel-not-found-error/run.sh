#!/usr/bin/env bash
# QEMU -kernel/-bios 加载失败真复现：
#   1) -kernel 路径不存在（拼错）：No such file or directory + could not load kernel；
#   2) 相对路径依赖工作目录：同一命令在错误 cwd 报找不到，回到正确 cwd 即越过加载阶段；
#   3) 文件存在但加载不了：目录（Is a directory）、空文件、非 ELF 内容被静默当裸固件加载；
#   4) -bios 是另一套报错措辞：缺失报 Unable to find the RISC-V BIOS，非 ELF 先警告再回退裸加载。
# 会挂起的场景用「后台启动 + sleep + kill」守卫收尾（macOS 无 timeout 命令）。
set -uo pipefail
cd "$(dirname "$0")"
rm -rf build
mkdir -p build/subdir build/kernels
cd build

QEMU="qemu-system-riscv64 -machine virt -nographic -display none"

# 守卫：后台跑 N 秒后杀掉，专用于 QEMU 成功加载后挂在串口上的场景
guard() {
  local secs=$1; shift
  "$@" &
  local p=$!
  sleep "$secs"
  kill "$p" 2>/dev/null
  wait "$p" 2>/dev/null
}

echo '$ bash run.sh'
echo "== 0. 工具版本 =="
qemu-system-riscv64 --version | head -1
echo

echo "== 1. 故障一：-kernel 指向不存在的绝对路径（路径拼错）=="
qemu-system-riscv64 -machine virt -nographic -display none -kernel "$PWD/vmlinuz-missing"
echo "exit=$?"
echo

echo "== 2. 故障二：相对路径依赖工作目录，换个 cwd 同一条命令就失效 =="
head -c 512 /dev/urandom > kernels/vmlinuz
echo "-- 2a. 在错误 cwd（subdir）里引用 ./kernels/vmlinuz，文件实际在上一级 --"
(
  cd subdir
  qemu-system-riscv64 -machine virt -nographic -display none -kernel ./kernels/vmlinuz
  echo "exit=$?"
)
echo "-- 2b. 修复：回到正确 cwd 后同一条命令不再报加载错误，进入默认 OpenSBI 启动（3 秒后守卫杀掉）--"
guard 3 qemu-system-riscv64 -machine virt -nographic -display none -kernel ./kernels/vmlinuz | head -6
echo

echo "== 3. 故障三：文件存在但内核加载失败的三种形态 =="
mkdir -p adir
: > empty.bin
head -c 512 /dev/urandom > garbage.bin
echo "-- 3a. -kernel 指向目录 --"
qemu-system-riscv64 -machine virt -nographic -display none -kernel ./adir
echo "exit=$?"
echo "-- 3b. -kernel 指向 0 字节空文件 --"
qemu-system-riscv64 -machine virt -nographic -display none -kernel ./empty.bin
echo "exit=$?"
echo "-- 3c. -kernel 指向非 ELF 的随机字节：不报错，静默当裸固件加载并回退 OpenSBI（3 秒后守卫杀掉）--"
guard 3 qemu-system-riscv64 -machine virt -nographic -display none -kernel ./garbage.bin | head -6
echo

echo "== 4. -bios 是另一套报错措辞 =="
echo "not an elf" > note.txt
echo "-- 4a. -bios 文件不存在 --"
qemu-system-riscv64 -machine virt -nographic -display none -bios ./fw-missing.bin
echo "exit=$?"
echo "-- 4b. -bios 指向非 ELF 文本：先警告 ELF 加载失败、回退裸加载后挂起（3 秒后守卫杀掉）--"
guard 3 qemu-system-riscv64 -machine virt -nographic -display none -bios ./note.txt | head -4
echo "-- 4c. 混用：-kernel 给垃圾文件、-bios 给缺失路径，-bios 的错误优先报出 --"
qemu-system-riscv64 -machine virt -nographic -display none -kernel ./garbage.bin -bios ./fw-missing.bin
echo "exit=$?"
echo "done"
