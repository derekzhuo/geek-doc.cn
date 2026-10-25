# ts-yosys-cant-open-input-file：yosys Cant open input file 复现

**对应教程**：https://geek-doc.cn/eda/ts-yosys-cant-open-input-file.html（上线后生效）

## 环境

- eda-golden 镜像云主机（Ubuntu 22.04）：yosys 0.9 / Verilator 4.038 / iverilog 11.0
- 日期：2026-10-26；原始输出见同目录 *.log

## 复现

```bash
yosys -p "read_verilog wrong_path/top.v"   # 路径错触发 ERROR: Can't open input file
yosys -p "read_verilog n5_top.v; synth"    # 正确路径通过
```
