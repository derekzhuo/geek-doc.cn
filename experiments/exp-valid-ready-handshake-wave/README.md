# exp-valid-ready-handshake-wave

> **对应教程**：https://geek-doc.cn/chip-design/beginner/exp-valid-ready-handshake-wave.html（文档上线后生效）

valid/ready 握手反压实验：带流水寄存器的 valid-ready 管道，下游随机拉低 ready 制造反压，testbench 校验「数据保持到握手完成」语义与传输不丢不重。

## 环境

- iverilog + vvp（Icarus Verilog，支持 -g2012）
- 本实验在 eda-golden-v1 容器镜像内跑出，Linux 安装 iverilog 后可直接复现

## 复现

`bash run.sh`（带随机反压的 valid/ready 管道仿真，校验数据完整性并输出 VCD）
