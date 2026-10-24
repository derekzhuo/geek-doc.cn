# exp-axi-lite-slave-cocotb

> **对应教程**：https://geek-doc.cn/chip-design/intermediate/exp-axi-lite-slave-cocotb.html（文档上线后生效）

AXI4-Lite 从机寄存器块实验：带 4 个 32 位寄存器的 AXI-Lite slave，自检 testbench 覆盖写读回、地址解码与错误响应，仿真非零退出即失败。

## 环境

- iverilog + vvp（仿真）；yosys（综合统计，可选）
- 本实验在 eda-golden-v1 容器镜像内跑出

## 复现

`make run`（编译+自检 testbench）；`make synth`（yosys 综合统计）
