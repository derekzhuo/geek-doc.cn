# ts-verilator-multidriven-MULTIDRIVEN：Verilator MULTIDRIVEN 告警复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-multidriven-MULTIDRIVEN.html（上线后生效）

## 环境

- eda-golden 镜像云主机（Ubuntu 22.04）：yosys 0.9 / Verilator 4.038 / iverilog 11.0
- 日期：2026-10-26；原始输出见同目录 *.log

## 复现

```bash
verilator --lint-only -Wall n2_bad.v    # 双时钟双 always 驱动同一 reg 触发 %Warning-MULTIDRIVEN
verilator --lint-only -Wall n2_fixed.v  # 合并后 0 告警
# n2a/n2b/n2c 为多驱动三场景对照（多 always / 多 assign / 跨模块）
```
