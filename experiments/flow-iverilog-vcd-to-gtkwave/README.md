# flow-iverilog-vcd-to-gtkwave

**对应教程**：https://geek-doc.cn/eda/flow-iverilog-vcd-to-gtkwave.html

iverilog/vvp 导出 VCD 波形的最小对照实验：同一层级设计（tb -> cnt_top -> inc_add），对比 `$dumpvars` 深度 0/1/2 导出的 scope 与变量差异，并演示 `$dumpoff`/`$dumpon`/`$dumpall` 的记录时间窗控制。

## 文件

| 文件 | 作用 |
|---|---|
| `counter.v` | 两层层级的 8 位计数器（cnt_top 内挂 inc_add 子模块） |
| `tb_d0.v` / `tb_d1.v` / `tb_d2.v` | dump 深度 0（全层次）/ 1（仅 TB 层）/ 2（TB + dut 层） |
| `tb_window.v` | 100ns-200ns 暂停记录，恢复时用 `$dumpall` 补全量快照 |
| `run.sh` | 自动编译运行并统计 scope/var/时间戳数、摘录 VCD 文本段 |
| `Makefile` | `make run` 复现；`make gtkwave` 打开全层次波形（需本机装 GTKWave） |

## 复现

```bash
# 需要 Icarus Verilog 13.0（更低版本亦可）
make run
# macOS 安装查看器：brew install --cask gtkwave
make gtkwave
```

产物 `depth0.vcd` / `depth1.vcd` / `depth2.vcd` / `window.vcd` 为运行生成，不入库。
