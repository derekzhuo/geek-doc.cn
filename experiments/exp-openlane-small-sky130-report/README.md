# exp-openlane-small-sky130-report

> **对应教程**：https://geek-doc.cn/eda-lab/backend/exp-openlane-small-sky130-report.html（文档上线后生效）

OpenLane 小设计全流程实验：一个最小计数器在 sky130A PDK 上跑通 RTL 到 GDS 的完整后端流程，用面积报告、DRC 日志与 LVS 结果三处验收点确认流程走通。

## 环境

- Docker 镜像 efabless/openlane（OpenLane 1.x，flow.tcl 入口）
- volare 安装的 sky130A PDK（PDK_ROOT=$HOME/.volare）
- 设计目录以 bind mount 挂入容器（Makefile 内 -v $(LAB_DIR):/designs/small_counter）

## 复现

`make run`（容器内跑完整 RTL→GDS 流程，报告落在 runs/golden_smoke/ 下）
