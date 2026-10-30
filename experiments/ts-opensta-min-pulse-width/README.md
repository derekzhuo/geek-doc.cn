# OpenSTA 最小脉宽违规：波形对照实验

**对应教程**：https://geek-doc.cn/eda/ts-opensta-min-pulse-width.html（上线后生效）

同一 DFF 网表和同一 Liberty 库分别加载两份 SDC，观察 `min_pulse_width` 的 VIOLATED 与无违规报告。库规定时钟高、低电平都不得小于 2ns；违规组使用 4ns 周期和 `{0 1}` 波形，满足组使用 10ns 周期和 `{0 5}` 波形。

## 文件

- `top.v`：只有一个 DFF 的最小网表。
- `experiment.lib`：含 DFF 最小时序弧和时钟引脚最小脉宽约束的教学库，不对应任何可制造 PDK。
- `violation.sdc` / `pass.sdc`：只改变时钟周期与波形的两份约束。
- `check.tcl`：加载设计并输出时钟属性、最小脉宽路径与全部违规。
- `run.sh`：依次运行两组对照并保留退出码。
- `run1.log`：原始运行输出。

## 复现

安装 OpenSTA 后在本目录执行：

```bash
bash run.sh
```

也可用 `LOG_PATH=/path/to/run1.log bash run.sh` 指定日志位置。实验使用 OpenSTA 2.0.17；所有数值只适用于这份教学库和 SDC，不能外推为工艺签核结论。
