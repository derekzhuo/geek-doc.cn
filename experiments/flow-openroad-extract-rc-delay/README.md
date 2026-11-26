# OpenROAD 布局 RC、全局布线 SPEF 与回读对照

**对应教程**：https://geek-doc.cn/eda/flow-openroad-extract-rc-delay.html

这个最小实验用六个缓冲器串联路径，对比布局后寄生估计、全局布线后的 SPEF，以及新进程回读 SPEF 的时序结果。输入是手写教学 LEF/Liberty，只用于验证命令顺序和数据交接，不代表真实 PDK，也不是详细布线后的 signoff 提取。

## 运行

准备 `geek-eda:0.5-asic` 镜像，在本目录执行：

```bash
make run
```

也可以直接执行：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'
```

容器需要 `openroad` 与 `python3`。`OR_BIN` 可覆盖 OpenROAD 可执行文件名。

## 阶段与断言

1. `00_probe.tcl` 确认 26Q4 镜像中可用的寄生与 SPEF 接口。此镜像没有 `extract_rc`、`report_parasitic`，实际使用 `estimate_parasitics`、`read_spef` 和 `report_parasitic_annotation`。
2. `01_place_estimate.tcl` 完成布局、合法化和 `estimate_parasitics -placement`，写出 `01_placed.def` 与路径报告。
3. `02_route_extract.tcl` 回读同一 DEF，执行 `global_route`，再用 `estimate_parasitics -global_routing -spef_file` 生成七条网的 SPEF。
4. `03_readback.tcl` 在独立进程中回读 DEF 和 SPEF，要求未标注及部分未标注驱动都为零。
5. `verify.py` 不依赖单个成功标记：检查三个阶段、输出文件非空、SPEF 的七个 `D_NET` 与七个 `RES` 段、路径中六个单元弧和七条互连弧，并验证单元加互连延迟能重建路径内部延迟。

## 本次结果

| 阶段 | 到达时间（ns，含固定 1ns 输入延迟） | 单元弧延迟（ns） | 互连弧延迟（ns） | 互连占路径内部延迟 |
|---|---:|---:|---:|---:|
| 布局估计 | 2.023846 | 0.240777 | 0.783069 | 76.4831% |
| 全局布线模型 | 1.119566 | 0.115879 | 0.003687 | 3.0839% |
| 独立 SPEF 回读 | 1.114736 | 0.114736 | 0.000000（报告精度） | 0.0000%（报告精度） |

SPEF 回读的零互连弧只是本版本默认延迟视图和 JSON 报告精度下的结果，不能解释为 SPEF 没有电阻；文件中的七段 `RES` 已单独检查。生成端与回读端到达时间相差 0.004830ns，因此脚本用 0.006ns 容差检查同一路径的一致性，而不要求每一位完全相等。

`results/run.log` 保存完整运行记录，`results/verify.log` 保存延迟拆分与最终断言，阶段日志、SPEF 和文本路径报告也一并保留。DEF、guide 和 JSON 路径报告可由 `make run` 重新生成。

## 变量与边界

- `set_wire_rc -resistance 5.0 -capacitance 0.001` 是教学单位线 RC；金属层 LEF 的 `RPERSQ/CPERSQDIST` 同样只服务这个夹具。
- 修改网表、布局、单元库、RC、SDC 或 OpenROAD 版本都会改变数值；比较时必须保持其余输入不变。
- 本流程停在全局布线寄生模型。详细布线后的 RCX 需要完整提取规则和工艺数据；在这份极简 LEF 上直接执行 `extract_parasitics -lef_rc` 会报告没有 RC model，不能写出有效 SPEF。
- 当前 SDC 使用 20ns 虚拟时钟与 1ns IO 延迟，便于观察路径延迟，不用于证明某个真实设计的时序收敛。
