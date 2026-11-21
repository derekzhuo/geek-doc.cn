# flow-opensta-false-multicycle-path

**对应教程**：https://geek-doc.cn/eda/flow-opensta-false-multicycle-path.html（上线后生效）

同一个门级设计分别加载无例外、false path、multicycle path 三版 SDC，用 OpenSTA 对照 setup/hold 检查沿、slack 与路径是否仍被分析。

## 文件

- `top.v`：同一个时钟始终运行。`run_en=0` 时功能寄存器保持、配置寄存器继续采样；`run_en=1` 时 `u_phase` 每拍翻转，`u_a` 与 `u_b` 共用 `sample_en = run_en && !phase`，只在同一相位每两拍更新一次。
- `sim_cells.v`、`protocol_tb.v`：功能仿真单元模型与协议测试，检查中间沿保持、双拍捕获和维护窗内配置更新。仿真模型把 DFF 初值设为 0；STA 不读取此模型。
- `teaching.lib`：教学 Liberty，包含 DFF_P、NAND2、BUF_X，标量延迟不代表真实工艺。
- `base.sdc`：0.60 ns 时钟，setup/hold uncertainty 均为 0。
- `false_path.sdc`：只切除配置寄存器到影子寄存器的路径。维护控制器必须在 `run_en=0` 期间完成配置并等待稳定，再恢复功能采样。
- `multicycle.sdc`：数据路径 `setup 2` 与 `hold 1` 成对声明。
- `baseline.tcl`、`false_path.tcl`、`multicycle.tcl`：三个独立分析入口，共用 `report.tcl` 定点检查两条路径的 setup 和 hold。
- `results/`：协议测试与三份 STA 完整日志，以及 `summary.txt` 汇总。

OpenSTA 2.0.17 没有导出 `report_exceptions` 命令；脚本探测到这一版本边界后，使用带明确 `-from/-to` 的 `report_checks` 验证路径命中、消失及检查沿。具备该命令的版本会在同一位置直接执行 `report_exceptions`。

## 复现

```bash
make run
# 或使用与本次一致的镜像
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash run.sh'
```

## 本次结果

时钟周期 0.60 ns；DFF C→Q 为 0.20 ns，每级 NAND2 为 0.15 ns，DFF setup 为 0.10 ns，hold 为 0。捕获保持 mux 使数据支路包含四级 NAND2，到达时间为 0.80 ns；配置支路仍为三级 NAND2，到达时间为 0.65 ns。以下 slack 均为 ns。

| SDC | 数据 setup | 数据 hold | 配置 setup | 配置 hold |
|---|---:|---:|---:|---:|
| 无例外 | -0.30 VIOLATED | 0.80 MET | -0.15 VIOLATED | 0.35 MET |
| 配置 false path | -0.30 VIOLATED | 0.80 MET | removed | removed |
| 数据 multicycle 2 / hold 1 | 0.30 MET | 0.80 MET | -0.15 VIOLATED | 0.35 MET |

这些数字只解释教学库中的约束计算，不构成任何工艺或完整芯片的时序签核结论。
