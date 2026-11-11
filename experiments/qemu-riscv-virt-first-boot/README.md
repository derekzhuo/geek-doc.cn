# qemu-riscv-virt-first-boot：零工具链跑通第一个 RISC-V 虚拟平台

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-install-first-riscv-virt.html>

不装任何 RISC-V 交叉编译器，只用 QEMU 自带固件完成五件事：确认版本、查看 `virt` 机器模型、启动内置 OpenSBI 看到 SBI 横幅、导出虚拟开发板的设备树、创建 qcow2 磁盘镜像。

## 依赖

- QEMU（macOS：`brew install qemu`；Ubuntu：`apt install qemu-system-misc qemu-utils`）
- `dtc`（可选，用来把 DTB 反编译成可读 DTS；macOS 上随 QEMU 依赖安装）

## 复现

```bash
chmod +x run.sh
./run.sh | tee run1.log
```

脚本会把 QEMU 启动控制在 4 秒内自动结束（macOS 没有 `timeout` 命令，用后台进程 + `kill` 实现有界运行），产物落在 `output/`（已 gitignore）：

- `virt.dtb`：`virt` 机器的设备树二进制
- `disk.qcow2`：64MB 稀疏磁盘镜像，初始占用仅约 200KB
