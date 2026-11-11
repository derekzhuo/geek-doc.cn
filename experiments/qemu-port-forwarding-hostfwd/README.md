# qemu-port-forwarding-hostfwd：SLIRP hostfwd 端口转发实验

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-port-forwarding-hostfwd.html>

SLIRP 用户态网络里，客户机在 NAT 后面，主机无法直接连客户机端口。`hostfwd` 让 QEMU 在主机上开监听端口，把连接转发进客户机。本实验取三层证据：

1. QMP 执行 `info usernet`，看到 `TCP[HOST_FORWARD]` 转发表（2222→客户机 22、8080→客户机 80）；
2. 主机侧 `lsof` 看到 qemu 进程确实监听 2222/8080，`nc -z` 探活成功；
3. 阴性对照：另一台不带 `hostfwd` 的虚拟机存活期间，同样的 2222 端口连接被拒。

## 依赖

- QEMU（含 `qemu-system-riscv64`）。macOS：`brew install qemu`；Ubuntu：`apt install qemu-system-misc`。
- `nc`（Unix 套接字与端口探活）、`lsof`（macOS 自带；Linux 可用 `ss -ltnp` 替代）。

## 复现

```bash
chmod +x run.sh
./run.sh | tee run1.log
```

虚拟机均通过 QMP `quit` 自行退出。产物落在 `output/`（已 gitignore）。
