# exp-round-robin-arbiter-sim

> **对应教程**：https://geek-doc.cn/chip-design/beginner/exp-round-robin-arbiter-sim.html（文档上线后生效）

固定优先级 vs 轮转仲裁仿真对照：4 路请求在相同激励下分别过 fixed 与 round-robin 仲裁器，统计各请求者的授权次数，直观看公平性差异。

## 环境

- iverilog + vvp（Icarus Verilog，支持 -g2012）
- 本实验在 eda-golden-v1 容器镜像内跑出，Linux 安装 iverilog 后可直接复现

## 复现

`bash run.sh`（同一激励下对比固定优先级与轮转仲裁的授权分布）
