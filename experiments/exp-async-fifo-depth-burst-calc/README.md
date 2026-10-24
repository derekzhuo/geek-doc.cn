# exp-async-fifo-depth-burst-calc

> **对应教程**：https://geek-doc.cn/chip-design/intermediate/exp-async-fifo-depth-burst-calc.html（文档上线后生效）

异步 FIFO 深度计算对照实验：深度满足突发需求（AW=4，深 16）的一组 PASS，深度减半（AW=2，深 4）的一组溢出丢数 FAIL，验证「深度 = 突发长度 − 突发期间读出数」的选型公式。

## 环境

- iverilog + vvp（Icarus Verilog，支持 -g2012）
- 本实验在 eda-golden-v1 容器镜像内跑出，Linux 安装 iverilog 后可直接复现

## 复现

`bash run.sh`（默认输出到 /tmp/evidence/exp-async-fifo-depth-burst-calc/）
