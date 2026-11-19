# qemu-gdbstub-connect-errors

**对应教程**：https://geek-doc.cn/soc-qemu/qemu-gdbstub-connect-errors.html

复现 gdb 连不上 QEMU gdbstub 的三类现场，并附一组健康连接对照，全部在 macOS 本机 QEMU 11.1.2 + riscv64-elf-gdb 18.1 上真实运行：

1. **healthy**：`-s -S` 冻结启动，gdb 干净连上 1234 端口并读到复位 PC `0x1000`，退出码 0。
2. **no-stub**：启动参数不带 `-s`，1234 无监听，gdb 报 `could not connect: Operation timed out`（macOS 文案；Linux 上通常是 Connection refused），退出码 1。
3. **port-busy**：第一台 QEMU 占用 1234，第二台 `-s` 抢端口，报 `Failed to find an available port: Address already in use` 与 `gdbstub: couldn't create chardev`，自行退出且退出码 1。
4. **arch-mismatch**：gdb 误设 `riscv:rv32` 连 rv64 目标，报 `Selected architecture riscv:rv32 is ambiguous with reported target architecture riscv:rv64`，连接不断但按错误位宽解读，修法是改回 `riscv:rv64` 或 `auto`。

## 文件

- `common.sh`：虚拟机起停、QMP 套接字等待与 gdb 批处理公共函数。
- `run.sh`：四组实验顺序执行，逐组打印退出码，stdout/stderr 合并。
- `run1.log`：一次完整运行的原始记录。

## 复现方式

```bash
bash run.sh
```

依赖 `qemu-system-riscv64`、`riscv64-elf-gdb` 与 `nc`，无需任何固件文件（QEMU 内置 OpenSBI `-bios default`）。
