# qemu-gdb-multiarch-setup：跨架构 gdb 环境与 QEMU gdbstub 连接实验

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-gdb-multiarch-setup.html>（随站点发布后生效）

调试 QEMU 里的 RISC-V 虚拟机不能用系统自带的原生 gdb：它只认识本机架构，需要目标专属的 `riscv64-elf-gdb`（macOS/Homebrew 路径）或 Linux 上一份后端齐全的 `gdb-multiarch`。本实验把环境搭建、`.gdbinit` 模板连接和架构误配告警三件事跑成可复现脚本，全程只用 QEMU 自带 OpenSBI 固件，不需要客户机系统。

- `01-toolchain-selfcheck.sh`：核验 QEMU 与交叉 gdb 版本，列出专属 gdb 支持的架构清单，并用 `set architecture i386` 的真实报错说明单目标 gdb 与 `gdb-multiarch` 的边界。
- `02-gdbinit-template-connect.sh`：用 `-x` 加载 `templates/qemu-riscv64.gdbinit` 一键连上 `-s -S` 冻结的虚拟机，核对架构锁定为 `riscv:rv64`、PC 停在复位向量 `0x1000`。
- `03-wrong-arch-negative.sh`：把 gdb 误设成 `riscv:rv32` 连 rv64 虚拟机，抓 `ambiguous with reported target architecture riscv:rv64` 告警；再用 `set architecture auto` 恢复干净连接做对照。

## 依赖

- QEMU（含 `qemu-system-riscv64`）。macOS：`brew install qemu`；Ubuntu：`apt install qemu-system-misc`。
- RISC-V 交叉 gdb。macOS：`brew install riscv64-elf-gdb`；Ubuntu：`apt install gdb-multiarch`（脚本里的 `gdb` 名相应替换）。
- `nc` 支持端口探测与 Unix 套接字（macOS 自带）。

## 复现

```bash
chmod +x *.sh
./01-toolchain-selfcheck.sh        | tee run1.log
./02-gdbinit-template-connect.sh   | tee run2.log
./03-wrong-arch-negative.sh        | tee run3.log
```

每个脚本各自后台起一台冻结虚拟机、跑完 gdb 批处理后收掉进程，不需要手动交互。产物落在 `output/`（已 gitignore）。
