# exp-makefile-eda-project-layout

> **对应教程**：https://geek-doc.cn/eda-lab/sim/exp-makefile-eda-project-layout.html（文档上线后生效）

EDA 工程目录模板：rtl/ 与 tb/ 分离，Makefile 提供 run（编译+仿真）、lint（verilator -Wall）、clean 三个目标的最小工程骨架。

## 环境

- iverilog + verilator + make
- 本实验在 eda-golden-v1 容器镜像内跑出

## 复现

`bash run.sh`（或进入目录后 `make run` / `make lint` / `make clean`）
