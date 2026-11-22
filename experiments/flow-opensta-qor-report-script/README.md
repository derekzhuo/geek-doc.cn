# flow-opensta-qor-report-script

**对应教程**：https://geek-doc.cn/eda/flow-opensta-qor-report-script.html（上线后生效）

OpenSTA QoR 报表脚本化实验：用 `group_path` 按功能块建路径组，用 Tcl 遍历全部寄存器端点，汇总每个路径组的 WNS/TNS、违例条数与最差路径，并结合传播时钟的引脚级时钟到达时间输出全量时钟偏斜表，最后由固定格式的 `QOR_GATE` 行做门禁判定。

## 重要边界

`teaching.lib` 是标量常数延迟的教学库（DFF_P、NAND2、BUF_X 三个单元），不代表任何真实工艺；时钟树由网表里的 BUF_X 链构成，`set_propagated_clock` 后各寄存器时钟引脚得到 0.10/0.20/0.40 ns 的真实传播到达时间。两个 SDC 版本共用同一份 DUT，仅时钟周期不同：`pass.sdc` 为 4.0 ns（全 PASS），`fail.sdc` 收紧到 0.5 ns（DATA 组两条 setup 违例）。

## 文件

- `top.v`：CTRL/DATA 两个功能块的 DUT，含四级 BUF 时钟树。
- `teaching.lib`：最小教学 Liberty。
- `common.tcl`：读库、读网表、link。
- `pass.sdc` / `fail.sdc`：满足版与违例版约束，均用 `group_path` 建 CTRL、DATA 路径组。
- `qor.tcl`：QoR 汇总脚本（偏斜表、分组 WNS/TNS、端点覆盖审计、QOR_GATE 门禁）。
- `pass.tcl` / `fail.tcl`：两个场景的驱动脚本。
- `run.sh`：依次运行两个场景，解析 `QOR_GATE` 行并校验「满足版必须 PASS、违例版必须 FAIL」的预期。
- `results/`：本次运行的两份场景日志。

## 复现

```bash
make run
# 或使用本实验采用的镜像
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash run.sh'
```

本机已装 OpenSTA 时也可 `STA_BIN=sta bash run.sh`。注意路径违例时 `sta` 进程退出码仍是 0，门禁状态以日志中的 `QOR_GATE` 行为准。

## 关键结果（2026-11-23 实测）

| 场景 | 全局时钟偏斜 | setup WNS | setup TNS | setup 违例端点数 | hold WNS | 门禁 |
|---|---:|---:|---:|---:|---:|---|
| pass（4.0 ns） | 0.3000 ns | 3.4000 ns | 0.0000 ns | 0 | 0.0500 ns | PASS |
| fail（0.5 ns） | 0.3000 ns | -0.1000 ns | -0.2000 ns | 2 | 0.0500 ns | FAIL |

OpenSTA 2.0.17 自带的 `report_clock_skew` 在本设计上只输出最先遍历到的一对时钟引脚，全量五个寄存器时钟引脚的偏斜表由 `qor.tcl` 从 `report_checks` 的捕获侧时钟网络延迟逐引脚提取，日志中同时保留了内置命令输出作为对照。
