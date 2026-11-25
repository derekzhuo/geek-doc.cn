# qemu-firmware-single-step：从复位到 U-Boot 的地址级调试

**对应教程**：https://geek-doc.cn/soc-qemu/qemu-firmware-single-step.html

用 QEMU 内置 OpenSBI 和 Ubuntu 固定版本的 RISC-V U-Boot，演示复位 PC、OpenSBI 反汇编与寄存器观察、两次单步，以及进入 `0x80200000` 的 U-Boot 后再单步。固件没有附带符号表，因此实验使用已从 OpenSBI 启动信息验证的地址，不假设存在 `main` 符号。

## 依赖

- QEMU 系统模拟器 `qemu-system-riscv64`
- `riscv64-elf-gdb`，或 Linux 上的 `gdb-multiarch`
- `curl`、`ar`、`tar` 和 SHA-256 工具
- macOS 与 Linux；脚本使用 bash

## 复现

```bash
chmod +x run.sh
./run.sh
```

脚本只下载并校验 `u-boot-qemu_2024.01+dfsg-1ubuntu5_all.deb`，不需要 Ubuntu 磁盘镜像，也不启动完整操作系统。下载文件和解包结果位于 `assets/`，串口与 GDB 日志位于 `output/`。

默认 GDB 端口为本机 `127.0.0.1:1240`，可用 `GDB_PORT=1241 ./run.sh` 避开已占用端口；也可通过 `QEMU` 和 `GDB` 环境变量指定工具路径。每次只运行一个相同端口的实例。
