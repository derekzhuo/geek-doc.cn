# exp-yosys-verilator-quickstart

> **对应教程**：https://geek-doc.cn/eda-lab/sim/exp-yosys-verilator-quickstart.html（文档上线后生效）

Yosys + Verilator 快速上手：对一个七段数码管演示模块跑完整四步流程——Yosys 综合看资源、Verilator lint 查问题、Icarus 仿真验功能、输出 VCD 波形。

## 环境

- yosys + verilator + iverilog
- 本实验在 eda-golden-v1 容器镜像内跑出

## 复现

`bash run.sh`（四步：yosys 综合 → verilator lint → iverilog 仿真 → VCD 产物）
