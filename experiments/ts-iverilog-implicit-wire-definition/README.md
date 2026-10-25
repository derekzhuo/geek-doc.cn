# ts-iverilog-implicit-wire-definition：iverilog implicit definition of wire 复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-implicit-wire-definition.html（上线后生效）

## 环境

- eda-golden 镜像云主机（Ubuntu 22.04）：yosys 0.9 / Verilator 4.038 / iverilog 11.0
- 日期：2026-10-26；原始输出见同目录 *.log

## 复现

```bash
iverilog -Wimplicit -o /dev/null n6_bad.v n6_sub.v            # 端口拼写错触发隐式声明 warning
iverilog -Wimplicit -o n6_tb.vvp n6_tb.v n6_bad.v n6_sub.v && vvp n6_tb.vvp   # 波形对拍
iverilog -o /dev/null n6_none.v n6_sub.v                      # `default_nettype none` 直接报错
```
