# exp-fsm-encoding-yosys

> **对应教程**：https://geek-doc.cn/chip-design/intermediate/exp-fsm-encoding-yosys.html（文档上线后生效）

FSM 状态编码综合对比：同一状态机分别用 binary、one-hot、gray 编码实现，用 Yosys stat 对比三者的单元数、线网数与触发器数量。

## 环境

- yosys（synth + stat）
- 本实验在 eda-golden-v1 容器镜像内跑出

## 复现

`bash run.sh`（对同一 FSM 的 binary / one-hot / gray 三种编码分别综合并输出对比表）
