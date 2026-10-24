# exp-multibit-cdc-glitch

> **对应教程**：https://geek-doc.cn/chip-design/intermediate/exp-multibit-cdc-glitch.html（文档上线后生效）

多比特跨时钟域毛刺对照实验：计数器值直接打拍同步会出现非法中间值，改用格雷码后每个时钟沿只翻转一位、非法值消失，仿真给出两组证据。

## 环境

- iverilog + vvp（Icarus Verilog，支持 -g2012）
- 本实验在 eda-golden-v1 容器镜像内跑出，Linux 安装 iverilog 后可直接复现

## 复现

`bash run.sh`（仿真直接同步与格雷码同步两条路径，统计非法中间值出现次数）
