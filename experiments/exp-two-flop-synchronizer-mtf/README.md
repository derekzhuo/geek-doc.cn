# exp-two-flop-synchronizer-mtf

> **对应教程**：https://geek-doc.cn/chip-design/beginner/exp-two-flop-synchronizer-mtf.html（文档上线后生效）

两级触发器同步器实验：异步单比特信号经 2-FF 同步器打两拍，testbench 实测从输入变化到输出跟随的延迟拍数，并输出 VCD 波形。

## 环境

- iverilog + vvp（Icarus Verilog，支持 -g2012）
- 本实验在 eda-golden-v1 容器镜像内跑出，Linux 安装 iverilog 后可直接复现

## 复现

`bash run.sh`（测量 2-FF 同步器的跟随延迟并输出 VCD）
