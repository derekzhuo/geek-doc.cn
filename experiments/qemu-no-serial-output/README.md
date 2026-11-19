# qemu-no-serial-output

**对应教程**：https://geek-doc.cn/soc-qemu/qemu-no-serial-output.html

复现「QEMU 启动后终端黑屏、没有串口输出」的四类现场，每类同时取终端侧 OpenSBI 横幅计数与 QMP `query-chardev` / `query-status` 的结构化证据，全部在 macOS 本机 QEMU 11.1.2 上真实运行：

1. **vc-backend**：`-display none` 且不用 `-nographic`，串口默认挂虚拟控制台 `vc`，终端横幅计数 0，`query-chardev` 显示 `serial0 -> vc`。
2. **serial-file**：`-serial file:...` 把输出写进文件，终端计数 0、文件内横幅计数 1，`serial0 -> file`。
3. **cpu-frozen**：`-S` 冻结 CPU，串口接线是 `stdio` 但 `query-status` 为 `prelaunch`，固件一条指令没跑，终端计数 0。
4. **stdio-conflict**：`-nographic` 已占用 stdio 再挂 `-monitor stdio`，QEMU 报 `cannot use stdio by multiple character devices` 与 `could not connect serial device to character backend 'stdio'`，启动即失败，退出码 1。

## 文件

- `run.sh`：四组实验顺序执行，QMP 调用与横幅计数自动取证，stdout/stderr 合并。
- `run1.log`：一次完整运行的原始记录。

## 复现方式

```bash
bash run.sh
```

依赖 `qemu-system-riscv64` 与 `nc`，无需自备固件（QEMU 内置 OpenSBI `-bios default`）。
