# QEMU RISC-V virt gdbstub 连接模板
# 用法：riscv64-elf-gdb -q -x templates/qemu-riscv64.gdbinit
# 虚拟机需先用 -s -S 启动（gdbstub 监听 1234，CPU 冻结在复位向量）。

# 1. 显式锁定目标架构，避免 auto 探测在无符号文件时给出歧义告警
set architecture riscv:rv64

# 2. 连接 QEMU 内置 gdbstub
target remote :1234

# 3. 有带符号固件时打开符号表（OpenSBI/U-Boot/内核 ELF），没有就先注释掉
# file build/fw_jump.elf

# 4. 停下时自动反汇编下一条指令，方便单步观察
set disassemble-next-line on
