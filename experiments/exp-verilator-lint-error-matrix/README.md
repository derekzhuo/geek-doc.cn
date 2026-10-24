# exp-verilator-lint-error-matrix

> **对应教程**：https://geek-doc.cn/chip-design/beginner/exp-verilator-lint-error-matrix.html（文档上线后生效）

Verilator lint 错误矩阵：9 个最小 .v 文件各触发一类典型告警（WIDTH/CASEINCOMPLETE/UNOPTFLAT/BLKSEQ/UNUSED/UNDRIVEN/LATCH/MULTIDRIVEN/IMPLICIT），一次收集全部报错文本。

## 环境

- verilator（--lint-only -Wall）
- 本实验在 eda-golden-v1 容器镜像内跑出

## 复现

`bash run.sh`（对 9 个各含一类典型问题的 .v 分别跑 verilator lint，非零退出是预期）
