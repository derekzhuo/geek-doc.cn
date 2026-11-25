# CMOS 反相器 VTC 与 Wp/Wn 扫描

**对应教程**：https://geek-doc.cn/chip-design/beginner/seed-inverter-vtc-sizing.html （文章上线后生效）

本实验用 ngspice 对同一个 CMOS 反相器做 DC 输入扫描。NMOS 固定为 `W=1 µm`，PMOS 分别取 `W=0.5/1/2/4 µm`，两管均为 `L=0.18 µm`。模型是文件 `cir/mos-models.inc` 中显式给出的 LEVEL=1 教学模型，不是 Sky130 模型、硅片实测或签核结果。

## 运行

需要 ngspice 42 或兼容版本、Python 3.8+（只用标准库）：

```bash
./run.sh
```

脚本逐档生成网表，运行 `ngspice -b`，导出每条曲线 1801 个点，然后生成 `results.csv` 和 `summary.json`。`verify.py` 会重新计算全部指标，检查单调性、`VIL < Vm < VIH`、非负噪声容限以及 Vm 随 Wp/Wn 增大的方向；全部通过时输出 `PASS`。

## 提取口径

- 扫描条件：VDD=1.8 V，27°C，输入步长 1 mV，负载 1 fF。
- `Vm`：`Vout - Vin` 首次变号的位置，相邻采样点之间线性插值。
- `VIL`、`VIH`：三点中心差分得到 `dVout/dVin`，分别在 Vm 左侧和右侧寻找 `dVout/dVin + 1` 的变号点并线性插值。
- `VOH=Vout(Vin=0)`，`VOL=Vout(Vin=VDD)`；`NML=VIL-VOL`，`NMH=VOH-VIH`。
- Vm 所在采样区间宽度为 1 mV；单位增益根使用中心差分序列，根两侧对应横坐标的区间宽度也为 1 mV。报告保留六位小数是为了复算一致，不代表具有微伏级物理精度；网格量化误差界限按半个步长，即 0.5 mV 解读。

## 本次结果

| Wp/Wn | Vm (V) | VIL (V) | VIH (V) | NML (V) | NMH (V) |
|---:|---:|---:|---:|---:|---:|
| 0.5 | 0.728762 | 0.577778 | 0.790927 | 0.577778 | 1.009073 |
| 1 | 0.799107 | 0.655340 | 0.882773 | 0.655340 | 0.917227 |
| 2 | 0.875032 | 0.750748 | 0.983475 | 0.750748 | 0.816525 |
| 4 | 0.952405 | 0.852972 | 1.084640 | 0.852972 | 0.715360 |

`data/vtc_wp_*.raw` 是 ngspice `wrdata` 原始导出，`results.csv` 是指标表，`data/ngspice_wp_*.log` 保留各档仿真输出。数据中的高精度尾数来自求解器和文本导出，不应理解为工艺精度。
