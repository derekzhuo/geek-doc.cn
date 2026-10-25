# ts-verilator-unusedsignal-UNUSED：Verilator UNUSEDSIGNAL/UNUSED 告警复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-unusedsignal-UNUSED.html（上线后生效）

## 环境

- eda-golden 镜像云主机（Ubuntu 22.04）：yosys 0.9 / Verilator 4.038 / iverilog 11.0
- 日期：2026-10-26；原始输出见同目录 *.log

## 复现

```bash
verilator --lint-only -Wall n4_bad.v      # 触发 UNUSED 告警
verilator --lint-only -Wall n4_delete.v   # 处置一：删除
verilator --lint-only -Wall n4_use.v      # 处置二：使用
verilator --lint-only -Wall n4_lintoff.v  # 处置三：lint_off 显式豁免
```
