# RISC-V virt Starter Kit

> **对应教程**：https://geek-doc.cn/soc-qemu/riscv-virt-starter-kit.html

一个可以在 macOS 或 Linux 上运行的 RISC-V 虚拟平台入门工程。下载预先构建的 Ubuntu 镜像与 U-Boot 后，即可启动到串口登录界面、连接 gdb 单步调试，并通过 SSH 进入客户机。全程不需要交叉编译器、Linux NBD 或 root 权限。

**第一次使用请直接打开 [START-HERE.md](START-HERE.md)。**

## 能学到什么

- QEMU `virt` 机器、OpenSBI、U-Boot 与 Ubuntu Linux 的启动顺序。
- 使用 qcow2 overlay 保留原始镜像，让每次实验从干净磁盘开始。
- 使用 NoCloud 注入演示用户、SSH 公钥和 DHCP 网络配置。
- 使用 `-S` 冻结复位现场，在 OpenSBI 入口打断点并单步。
- 使用 SLIRP `hostfwd` 把宿主回环地址的端口转发到客户机 SSH。

这是教学工程，不用于生产虚拟机，也不包含自定义外设、内核或固件源码构建。

## 环境要求

- macOS / Linux 与 Bash、`make`、`curl`、`ssh`。
- QEMU：`qemu-system-riscv64` 与 `qemu-img`。
- 调试：`riscv64-elf-gdb`；也可使用支持 RISC-V 的 `gdb-multiarch`，运行时设置 `GDB` 变量。
- macOS 使用自带 `hdiutil` 生成 NoCloud ISO；Linux 安装 `genisoimage` 或 `xorriso`。
- 首次下载约 800 MiB；建议至少保留 3 GiB 可用磁盘与 2 GiB 可供虚拟机使用的内存。

macOS 可使用 Homebrew 安装 QEMU。Ubuntu / Debian 可安装 `qemu-system-misc`、`qemu-utils`、`gdb-multiarch`、`genisoimage`。Windows 原生环境未验证，请在 WSL2 中使用 Linux 流程。

## 五条命令

```bash
make fetch   # 下载资产并逐个核对 SHA-256
make run     # 启动 Ubuntu，串口登录 ubuntu / riscv
make debug   # 冻结复位，命中 OpenSBI 断点并单步两次
make net     # 启动客户机，通过 SSH 执行命令并验证 riscv64
make test    # 无头检查 gdb 断点与 Ubuntu 登录提示
```

`make run` 会占用当前终端。看到 `riscv-virt login:` 后输入 `ubuntu`，密码为 `riscv`。退出 QEMU 串口控制台按 `Ctrl-a`，再按 `x`。

`make net` 自动完成 SSH 验证后退出。如果要在 `make run` 启动的同一台虚拟机里手动使用 SSH：

```bash
ssh -i output/id_ed25519 -p 2222 \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  ubuntu@127.0.0.1
```

演示密码和临时密钥仅用于本机回环地址。不要把这套配置直接用于公网或共享主机。

## 可调参数

| 环境变量 | 默认值 | 用途 |
|---|---:|---|
| `MEMORY` | `2048` | 客户机内存，MiB |
| `CPUS` | `2` | 虚拟 CPU 数 |
| `SSH_PORT` | `2222` | 宿主回环地址上的 SSH 转发端口 |
| `GDB_PORT` | `1234` | gdbstub 监听端口 |
| `QEMU` | `qemu-system-riscv64` | QEMU 可执行文件 |
| `GDB` | `riscv64-elf-gdb` | gdb 可执行文件 |

例如：`MEMORY=1024 CPUS=1 SSH_PORT=12222 make net`。

## 目录与产物

```bash
riscv-virt-starter-kit/
├── START-HERE.md
├── Makefile
├── .gdbinit
├── scripts/
│   ├── assets.manifest
│   ├── common.sh
│   ├── clean.sh
│   ├── fetch.sh
│   ├── run.sh
│   ├── debug.sh
│   ├── net.sh
│   └── test.sh
├── assets/       # 下载与解包的二进制资产，不入库
└── output/       # overlay、临时密钥、ISO 和日志，不入库
```

`make clean` 只删除运行产物；`make distclean` 同时删除下载资产。重复执行 `make run` 或 `make net` 会重建 overlay，上一次客户机内的修改不会保留；临时密钥在 `make clean` 前复用。各目标共用运行目录，不要并行启动多个目标。

## 配套教程

- [RISC-V virt 入门工程包](https://geek-doc.cn/soc-qemu/riscv-virt-starter-kit/)
- [QEMU 安装与第一次 RISC-V 启动](https://geek-doc.cn/soc-qemu/qemu-install-first-riscv-virt/)
- [QEMU gdbstub 工作原理](https://geek-doc.cn/soc-qemu/qemu-gdbstub-how-it-works/)
- [QEMU 端口转发](https://geek-doc.cn/soc-qemu/qemu-port-forwarding-hostfwd/)

## 许可

脚本与说明采用 [MIT](LICENSE)。下载的 Ubuntu 镜像和 U-Boot 保留各自上游许可。
