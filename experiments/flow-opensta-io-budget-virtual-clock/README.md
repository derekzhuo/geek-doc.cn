# flow-opensta-io-budget-virtual-clock

**对应教程**：https://geek-doc.cn/eda/flow-opensta-io-budget-virtual-clock.html（上线后生效）

同一个同步 UART 外壳的板级 IO 时序预算实验。`core_clk` 绑定内部寄存器时钟端口，无源的 `board_clk` 只提供片外发射与捕获参考沿；输入、输出分别给出 setup/hold 可手算闭合的 OpenSTA 报告。

## 重要边界

所有外部器件参数都是教学假设，不对应任何通用 UART 器件或真实数据手册：`tCO(max/min)=2.00/0.40 ns`、接收端 `tSU/tH=1.20/0.40 ns`、单向走线 0.35 ns、偏斜余量 0.10 ns。`teaching.lib` 是标量延迟教学库，不代表真实工艺。本例不描述标准异步 UART 的过采样与跨时钟同步。

## 文件

- `top.v`：RX 输入寄存器与 TX 输出寄存器组成的同一 DUT。
- `teaching.lib`：DFF_P、NAND2、BUF_X 最小 Liberty。
- `io_budget.sdc`：主预算，包含虚拟时钟及 input/output delay 的 max/min 数值来源。
- `baseline.tcl` / `dual_edge.tcl`：主模式与可选下降沿外部模式。
- `dual_edge.sdc`：用 `-clock_fall -add_delay` 保留原上升沿约束并追加第二种外部发射沿；它不是标准 UART 的默认行为。
- `report.tcl`：按 RX/TX、setup/hold 分别调用 `report_checks`。
- `summarize.py`：从真实报告提取 arrival、required、slack。
- `results/`：本次运行日志与汇总。

## 复现

```bash
make run
# 或使用本实验采用的镜像
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash -x run.sh'
```

结果写入 `results/baseline.log`、`results/dual_edge.log` 与 `results/summary.txt`。所有延迟单位为 ns。

## 主预算手算

| 路径 | arrival | required | slack |
|---|---:|---:|---:|
| RX setup | 2.45 + 0.15 = 2.60 | 10.00 - 0.10 = 9.90 | 7.30 MET |
| RX hold | 0.65 + 0.15 = 0.80 | 0.00 | 0.80 MET |
| TX setup | 0.20 + 0.10 = 0.30 | 10.00 - 1.65 = 8.35 | 8.05 MET |
| TX hold | 0.20 + 0.10 = 0.30 | 0.00 - (-0.15) = 0.15 | 0.15 MET |
