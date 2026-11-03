# Verilator 层次化编译（--hierarchical）对比实验

**对应教程**：https://geek-doc.cn/eda/flow-verilator-hierarchical.html

生成器产出「一个顶层 + 多个相同大模块实例」的可综合 RTL，分别用扁平编译与 `--hierarchical` 分块编译，用 `time` 实测两阶段耗时与产物结构。

## 环境

- Verilator 5.020（Debian 5.020-1）、g++、make、python3
- 推荐容器：`docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow bash run.sh`
- Debian 打包版的 hierarchical 子进程会去 `/usr/share/verilator/verilator_bin` 找二进制，`run.sh` 已自动补符号链接到 `/usr/bin/verilator_bin`

## 复现

```bash
# 默认 NB=16 个实例、每个 STAGES=4096 级、32 位宽（约 200 万触发器）、-j4
bash run.sh
# 自定义规模
NB=8 STAGES=2048 JOBS=8 bash run.sh
```

脚本依次跑 flat、hierarchical 两种模式，各记录 verilate 阶段、make 阶段的 `time` 输出，并追加两次 `touch` 增量构建计时。两种模式跑出来的仿真输出必须一致（`TB DONE q=0x...`）。

## 文件

- `gen.py`：RTL 生成器（参数：实例数、每实例流水级数、位宽）
- `rtl/top.v`、`rtl/bigblock.v`：生成器产出的示例 RTL（默认规模）
- `blocks.vlt`：层次化块配置（`` `verilator_config `` + `hier_block -module "bigblock";`）
- `sim/tb.cpp`：最小 C++ testbench
- `run.sh`：对比基准脚本

编译产物 `obj_dir/` 与可执行文件不入库。
