# exp-clock-gating-yosys-compare

> **对应教程**：https://geek-doc.cn/chip-design/intermediate/exp-clock-gating-yosys-compare.html（文档上线后生效）

使能寄存器与显式门控时钟两种低功耗写法的 Yosys 综合对比：同一份功能分别用 enable-mux 与 gated-clock 描述，对比综合后的单元数与线网数。

## 环境

- yosys（synth + stat）
- 本实验在 eda-golden-v1 容器镜像内跑出

## 复现

`bash run.sh`（yosys 分别综合 reg_en.v 与 reg_gated.v 并对比 cell/wire 统计）
