# ts-verilator-undriven-UNDRIVEN：Verilator UNDRIVEN 告警复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-undriven-UNDRIVEN.html（上线后生效）

## 环境

- eda-golden 镜像云主机（Ubuntu 22.04）：yosys 0.9 / Verilator 4.038 / iverilog 11.0
- 日期：2026-10-26；原始输出见同目录 *.log

## 复现

```bash
verilator --lint-only -Wall n1_bad.v    # 触发 %Warning-UNDRIVEN
verilator --lint-only -Wall n1_fixed.v  # 修复后 0 告警
```
