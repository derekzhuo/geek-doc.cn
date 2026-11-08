#!/bin/bash
# 在 x86_64 主机上直接运行 RISC-V ELF，走通 binfmt_misc 注册/注销/恢复全周期
# 依赖：gcc-riscv64-linux-gnu、qemu-user、qemu-user-static
set -u

echo "### 1. 交叉编译（静态 + 动态两个版本）"
riscv64-linux-gnu-gcc --version | head -1
riscv64-linux-gnu-gcc -static hello.c -o hello-riscv64
riscv64-linux-gnu-gcc hello.c -o hello-riscv64-dyn
file hello-riscv64 hello-riscv64-dyn

echo
echo "### 2. qemu-riscv64 显式转译"
qemu-riscv64 ./hello-riscv64; echo "exit=$?"

echo
echo "### 3. binfmt_misc 注册项（qemu-user-static 安装时注册 28 个架构）"
ls /proc/sys/fs/binfmt_misc/ | grep -c qemu
cat /proc/sys/fs/binfmt_misc/qemu-riscv64

echo
echo "### 4. 注册生效后直接执行（内核经 binfmt 自动调用 qemu-riscv64）"
./hello-riscv64; echo "exit=$?"

echo
echo "### 5. 临时注销，复现原生 Exec format error（退出码 126）"
echo -1 | sudo tee /proc/sys/fs/binfmt_misc/qemu-riscv64 >/dev/null
./hello-riscv64; echo "exit=$?"

echo
echo "### 6. systemd-binfmt 不会恢复 qemu-user-static（它登记在 update-binfmts）"
sudo systemctl restart systemd-binfmt
./hello-riscv64; echo "exit=$?"

echo
echo "### 7. 用 update-binfmts 恢复注册"
sudo update-binfmts --import qemu-riscv64
cat /proc/sys/fs/binfmt_misc/qemu-riscv64 | head -4
./hello-riscv64; echo "exit=$?"

echo
echo "### 8. 动态链接版需要 -L 指定 RISC-V sysroot"
qemu-riscv64 -L /usr/riscv64-linux-gnu ./hello-riscv64-dyn; echo "exit=$?"
