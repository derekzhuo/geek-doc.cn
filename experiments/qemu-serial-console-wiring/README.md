# qemu-serial-console-wiring：三种串口控制台接线对照实验

**对应教程**：<https://geek-doc.cn/soc-qemu/qemu-serial-console-wiring.html>

同样一块 `virt` 虚拟板，只改控制台参数，启动输出的去向完全不同。本实验对三种常见写法各跑一遍，并同时取两类证据：

| 模式 | 关键参数 | 串口接到哪里 |
|---|---|---|
| A | `-nographic` | 串口直连 stdio，并隐含关掉图形窗口 |
| B | `-display none -serial mon:stdio` | 串口与 monitor 经 mux 复用 stdio（`C-a c` 切换） |
| C | `-display none -serial null` | 串口接 null，输出全部丢弃 |

每轮实验：

1. 统计虚拟机 stdio 捕获文件里 OpenSBI 横幅的出现次数（A/B 为 1，C 为 0）；
2. 经 QMP `query-chardev` 取字符设备的结构化接线（`stdio` / `mux` / `null`）。

## 依赖

- QEMU（含 `qemu-system-riscv64`）。macOS：`brew install qemu`；Ubuntu：`apt install qemu-system-misc`。
- `nc` 支持 Unix 套接字（macOS 自带 `nc -U`）。

## 复现

```bash
chmod +x run.sh
./run.sh | tee run1.log
```

三轮虚拟机均通过 QMP `quit` 自行退出，不需要手动交互。产物落在 `output/`（已 gitignore）。
