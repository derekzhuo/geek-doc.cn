# 从这里开始

目标是在一台 macOS 或 Linux 主机上跑通 RISC-V Ubuntu 客户机，再验证 gdb 和 SSH 两条调试通道。

## 1. 检查工具

```bash
qemu-system-riscv64 --version
qemu-img --version
riscv64-elf-gdb --version
```

Linux 还要确认 `genisoimage` 或 `xorriso` 可用；macOS 不需要额外安装 ISO 制作工具。

## 2. 下载并校验资产

```bash
make fetch
```

每个下载物都必须出现 `SHA256 OK`。校验失败时脚本会停止，不会继续使用损坏或被替换的文件。资产地址与摘要固定保存在 `scripts/assets.manifest`。

## 3. 启动到串口登录

```bash
make run
```

首次启动需要等待系统初始化和 SSH 密钥生成。看到 `riscv-virt login:` 后使用：

- 用户名：`ubuntu`
- 密码：`riscv`

要退出 QEMU，按 `Ctrl-a`，再按 `x`。再次运行会新建 qcow2 overlay，不会改写下载的原始镜像。

## 4. 验证 gdb 调试

```bash
make debug
```

成功标志包括 `Breakpoint 1, 0x0000000080000000`、两次单步后的新 PC，以及末尾 `RESULT: PASS`。断点、继续和单步在同一个 gdb 会话完成，避免退出调试器后客户机继续运行、错过入口断点。

## 5. 验证 SSH

```bash
make net
```

脚本会等待客户机 SSH 就绪，执行 `uname -m`，确认输出为 `riscv64`，最后打印 `RESULT: PASS`。完整命令输出保存在 `output/net.log`。

## 6. 一次运行全部无头检查

```bash
make test
```

自检覆盖 gdb 断点和 Ubuntu 串口登录提示，适合修改脚本后回归。`output/` 下保留串口与调试日志。

## 常见问题

- **提示缺少命令：** 按错误信息安装对应工具，或检查 `PATH`。
- **端口被占用：** 换端口，例如 `SSH_PORT=12222 make net`、`GDB_PORT=11234 make debug`。
- **SSH 一直等待：** 查看 `output/net.serial.log`，先确认客户机已经启动到登录提示，再检查 cloud-init 与网络初始化信息。
- **想保留客户机修改：** 不要重复运行会重建 overlay 的命令，直接再次启动同一个 `output/vm.qcow2`，或先备份该文件。
- **需要从头下载：** `make distclean` 删除资产和运行产物，再执行 `make fetch`。
