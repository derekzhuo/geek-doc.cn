# exp-tcl-scripting-yosys-openroad

> **对应教程**：https://geek-doc.cn/eda-lab/synth/exp-tcl-scripting-yosys-openroad.html（文档上线后生效）

Yosys/OpenROAD Tcl 脚本化实验：把「读入 → 统计 → 选择重命名 → 综合输出」拆成四个 .ys 脚本分步执行，演示 EDA 工具的脚本批处理模式。

## 环境

- yosys（脚本模式 yosys -s）
- 本实验在 eda-golden-v1 容器镜像内跑出（镜像内未装 openroad，openroad 步骤自动 SKIP）

## 复现

`bash run.sh`（依次执行 s1_read/s2_stat/s3_select_rename/s4_synth_write 四个 .ys 脚本）
