# qemu-command-line-annotated：一条完整 QEMU 启动命令的逐参数实验

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-command-line-annotated.html>

把入门篇里那条 `qemu-system-riscv64` 命令拆开，每个参数都在本机真跑一遍验证效果：

- `-machine virt`：选择 RISC-V 通用虚拟开发板；
- `-bios default`：使用 QEMU 内置 OpenSBI 固件；
- `-m 256M` / `-smp 2`：客户机内存与核数；
- `-drive` + `-device virtio-blk-device`：给虚拟机挂一块 qcow2 数据盘；
- `-nographic` / `-serial mon:stdio` / `-no-reboot`：控制台接线与退出行为。

## 依赖

- QEMU（含 `qemu-system-riscv64`、`qemu-img`）。macOS：`brew install qemu`；Ubuntu：`apt install qemu-system-misc qemu-utils`。
- 任意 POSIX shell（macOS 自带 bash 3.2 可跑；用后台进程 + `kill` 实现有界运行，不依赖 GNU `timeout`）。

## 复现

```bash
chmod +x run.sh
./run.sh | tee run1.log
```

虚拟机启动 5 秒后自动结束，不需要手动交互。镜像产物落在 `output/`（已 gitignore），删掉即可完全复原。
