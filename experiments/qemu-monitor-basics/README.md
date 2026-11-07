# qemu-monitor-basics：QEMU monitor 运行时观测与快照实验

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-monitor-basics.html>

不进客户机系统，只靠 QEMU 的控制面就能观察和操作一台运行中的虚拟机。本实验用 QMP（QEMU Machine Protocol，JSON 机器协议）Unix 套接字连接后台虚拟机，再通过 `human-monitor-command` 执行经典 HMP 监控命令：

- `query-status`：QMP 原生查询，返回运行态 JSON；
- `info status` / `info block` / `info cpus`：HMP 命令族，看运行态、块设备、CPU 模型；
- `savevm snap1`：打内部快照，过程中能观察到 STOP/RESUME 事件；
- 虚拟机退出后用 `qemu-img snapshot -l` 从外部交叉验证快照确实落盘。

## 依赖

- QEMU（含 `qemu-system-riscv64`、`qemu-img`）。macOS：`brew install qemu`；Ubuntu：`apt install qemu-system-misc qemu-utils`。
- `nc` 支持 Unix 套接字（macOS 自带 `nc -U`；Linux 上 OpenBSD netcat 同参数）。

## 复现

```bash
chmod +x run.sh
./run.sh | tee run1.log
```

脚本自动后台起虚拟机、通过套接字发命令、最后收掉进程，不需要手动交互。产物落在 `output/`（已 gitignore）。
