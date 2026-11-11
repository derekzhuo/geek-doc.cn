#!/bin/bash
# 对照 qemu-user（单进程转译）与 qemu-system（整机模拟）
# 依赖：qemu-user、qemu-system-misc、一份 RISC-V 静态 ELF（见 ../qemu-user-cross-arch-binary）
set -u

HELLO=${1:-../qemu-user-cross-arch-binary/hello-riscv64}

echo "### A. user 态：qemu-riscv64 只转译单个进程，没有整机、没有常驻 qemu 进程"
qemu-riscv64 "$HELLO"
echo "残留 qemu 进程数: $(ps -eo comm | grep -c qemu || true)"

echo
echo "### B. system 态：起一台 virt 整机，-S 暂停在复位态，由 QMP 接管"
rm -f qmp.sock
qemu-system-riscv64 -machine virt -smp 2 -m 512M -nographic -S \
  -qmp unix:qmp.sock,server,nowait &
QPID=$!
sleep 2
echo "qemu 进程: $(ps -o pid,rss,comm -p $QPID | tail -1)"
python3 qmp-probe.py qmp.sock
wait $QPID 2>/dev/null
echo "qemu 退出码=$?"

echo
echo "### C. 两种模式的二进制与自省入口"
ls /usr/bin/qemu-riscv64 /usr/bin/qemu-system-riscv64
echo "virt 系机器模型数量: $(qemu-system-riscv64 -machine help | grep -c '^')"
