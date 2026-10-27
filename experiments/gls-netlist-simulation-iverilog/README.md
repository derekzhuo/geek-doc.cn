# 门级网表仿真（GLS）：RTL 与网表逐行比对（gls-netlist-simulation-iverilog）

**对应教程**：https://geek-doc.cn/chip-design/intermediate/gls-netlist-simulation-iverilog.html（上线后生效）

yosys 把 8-bit ALU 综合成通用门级网表，同一个自检 testbench（8 组激励：加/减/与/或/进位环绕/相等减/零标志）分别跑 RTL 与网表，两侧输出逐行一致、全 PASS。

## 文件

- `simple_alu.v` —— 8-bit ALU RTL
- `tb_alu.v` —— 自检 testbench，8 组激励逐组打印比对结果
- `output/gls.log` —— 综合 + RTL 仿真 + GLS 仿真三段完整日志

## 实验环境

- Ubuntu 22.04 + Yosys 0.9 + Icarus Verilog 11.0

## 复现

```bash
# ① 综合出门级网表
yosys -p "read_verilog simple_alu.v; synth -top simple_alu; write_verilog alu_gates.v"

# ② RTL 仿真
iverilog -g2012 -o sim_rtl.out tb_alu.v simple_alu.v && vvp sim_rtl.out

# ③ 门级仿真（带 yosys 通用单元仿真库）
SIMLIB=$(yosys-config --datdir)/techlibs/common/simlib.v
iverilog -g2012 -o sim_gls.out tb_alu.v alu_gates.v $SIMLIB && vvp sim_gls.out
```

## 关键结果

RTL 与门级网表两侧 8 组激励全部 OK、`TB_RESULT: PASS`，输出逐行相同——综合前后功能一致。
