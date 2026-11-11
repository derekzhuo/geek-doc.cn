# qemu-slirp-user-network：SLIRP 用户态网络默认行为实验

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-slirp-user-network.html>

QEMU 的默认网络后端是 SLIRP：一个跑在 QEMU 进程里的用户态 TCP/IP 协议栈，不需要 root 权限，也不在主机上创建网桥或虚拟网卡，客户机通过 NAT 访问外网。本实验用两次启动对照：

1. 不写任何网络参数 —— user 后端默认已在 hub 上（`type=user,net=10.0.2.0`），但 RISC-V `virt` 机器不会自动挂网卡前端；
2. 显式 `-netdev user,id=net0 -device virtio-net-device,netdev=net0` —— 这时才出现带 MAC `52:54:00:12:34:56` 的 virtio 网卡。

两轮都经 QMP 执行 HMP `info network`，观察后端、网卡模型、MAC 与默认网段 `10.0.2.0/24`。

## 依赖

- QEMU（含 `qemu-system-riscv64`）。macOS：`brew install qemu`；Ubuntu：`apt install qemu-system-misc`。
- `nc` 支持 Unix 套接字（macOS 自带 `nc -U`）。

## 复现

```bash
chmod +x run.sh
./run.sh | tee run1.log
```

虚拟机经 QMP `quit` 自行退出，无需交互。产物落在 `output/`（已 gitignore）。
