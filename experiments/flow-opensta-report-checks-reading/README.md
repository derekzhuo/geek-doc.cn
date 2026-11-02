# flow-opensta-report-checks-reading

**对应教程**：https://geek-doc.cn/eda/flow-opensta-report-checks-reading.html

OpenSTA `report_checks` 报告逐字段解读的最小复现实验：自写教学 liberty（仅含一个 DFF_P 与一个 BUF_X1，标量延时，不对应任何真实工艺）+ 两级 DFF 流水线网表（u_a -> BUF -> u_b），跑出三份报告用于对照：

- `met.tcl`：时钟周期 2.0ns，setup slack 1.40 MET、hold slack 0.50 MET（基线）；
- `fast.tcl`：同一设计提频到 0.5ns 周期，setup slack -0.10 VIOLATED；
- `latency.tcl`：`set_clock_latency 0.20`，观察 clock network delay 字段，发射/捕获同移 0.20，slack 不变。

## 复现

```bash
make run
# 或本机已装 OpenSTA 2.0.17：
STA_BIN=sta bash run.sh
```

## 文件

| 文件 | 内容 |
|---|---|
| `teaching.lib` | 教学用最小 liberty（DFF_P：CLK->Q 0.20、setup 0.10、hold 0.00；BUF_X1：0.30） |
| `top.v` | 两级 DFF + 一级 BUF 的门级网表 |
| `met.tcl` / `fast.tcl` / `latency.tcl` | 三个 STA 场景脚本 |
| `run.sh` | 依次跑三个场景并打印退出码 |

教学库数值仅用于演示报告字段，产线请替换为 PDK 提供的签核库。
