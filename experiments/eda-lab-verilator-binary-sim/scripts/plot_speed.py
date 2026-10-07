#!/usr/bin/env python3
# plot_speed.py —— 用 out/*_median.txt 的实测中位数画 iverilog vs verilator 对比图。
# 用法：python3 scripts/plot_speed.py  （在实验目录下运行）
# 产物：out/speed_compare.svg

import pathlib
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["PingFang SC", "Hiragino Sans GB", "sans-serif"]
plt.rcParams["axes.unicode_minus"] = False

ROOT = pathlib.Path(__file__).resolve().parent.parent
out = ROOT / "out"

iv = float((out / "iverilog_median.txt").read_text().strip())
vl = float((out / "verilator_median.txt").read_text().strip())
speedup = iv / vl

BLUE = "#2C7BE5"
GRAY = "#B0BEC5"

fig, ax = plt.subplots(figsize=(7.2, 3.2))
bars = ax.barh(
    ["iverilog (vvp)", "verilator --binary"],
    [iv, vl],
    color=[GRAY, BLUE],
    height=0.52,
)
for bar, val in zip(bars, [iv, vl]):
    ax.text(
        bar.get_width() + iv * 0.01,
        bar.get_y() + bar.get_height() / 2,
        f"{val:.2f} s",
        va="center",
        fontsize=11,
    )
ax.set_xlabel("仿真 1000 万拍墙钟时间（秒，3 次实测取中位数，越短越好）")
ax.set_title(
    f"verilator --binary 比 iverilog 快 {speedup:.1f} 倍（同一计数器 TB，实测）",
    fontsize=12,
)
ax.set_xlim(0, iv * 1.15)
ax.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig(out / "speed_compare.svg")
print(f"iverilog={iv}s verilator={vl}s speedup={speedup:.1f}x -> out/speed_compare.svg")
