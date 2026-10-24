# exp-sync-fifo-verilog-iverilog

> **对应教程**：https://geek-doc.cn/chip-design/beginner/exp-sync-fifo-verilog-iverilog.html（文档上线后生效）

同步 FIFO 的 Verilog 实现与 Icarus 回归：参数化深度/位宽的同步 FIFO，testbench 覆盖填满、读空、随机读写与指针环绕四类场景。

## 环境

- iverilog + vvp（Icarus Verilog，支持 -g2012）
- 本实验在 eda-golden-v1 容器镜像内跑出，Linux 安装 iverilog 后可直接复现

## 复现

`bash run.sh`（填满/读空/随机读写/环绕回归，输出 VCD）
