# ts-iverilog-syntax-near-token：iverilog syntax error near token 三类触发

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-syntax-near-token.html（上线后生效）

## 环境

- eda-golden 镜像云主机（Ubuntu 22.04）：yosys 0.9 / Verilator 4.038 / iverilog 11.0
- 日期：2026-10-26；原始输出见同目录 *.log

## 复现

```bash
iverilog -o /dev/null c1_semicolon.v   # 缺分号
iverilog -o /dev/null c1_paren.v       # 括号不配对
iverilog -o /dev/null c1_keyword.v     # 关键字误用
iverilog -o /dev/null c1_fixed.v       # 修复后通过
```
