#!/usr/bin/env python3
# Plot FSM encoding comparison from work/results.csv (real yosys/OpenSTA data).
import csv
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams["font.sans-serif"] = ["PingFang SC", "Heiti SC", "Arial Unicode MS", "DejaVu Sans"]
plt.rcParams["axes.unicode_minus"] = False

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", "public", "diagrams"))

BLUE, GRAY_C, ORANGE = "#2C7BE5", "#94A3B8", "#E08A1E"
ENC_STYLE = {"bin": ("binary", BLUE), "gray": ("gray", GRAY_C), "oh": ("one-hot", ORANGE)}

rows = list(csv.DictReader(open(os.path.join(HERE, "work", "results.csv"))))
sizes = sorted({int(r["nstates"]) for r in rows})
data = {e: {int(r["nstates"]): r for r in rows if r["enc"] == e} for e in ENC_STYLE}

x = np.arange(len(sizes))
w = 0.26

# ---- figure 1: FF count and total cell count ----
fig, axes = plt.subplots(1, 2, figsize=(9.2, 3.8))
for ax, key, title in (
    (axes[0], "ff", "触发器数量（DFF_P 单元）"),
    (axes[1], "cells", "单元总数（DFF + 组合逻辑）"),
):
    for i, (enc, (label, color)) in enumerate(ENC_STYLE.items()):
        vals = [int(data[enc][n][key]) for n in sizes]
        bars = ax.bar(x + (i - 1) * w, vals, w, label=label, color=color)
        ax.bar_label(bars, fontsize=8, padding=1)
    ax.set_title(title, fontsize=11)
    ax.set_xticks(x)
    ax.set_xticklabels([f"{n} 态" for n in sizes])
    ax.set_xlabel("状态数量")
    ax.grid(axis="y", linestyle="--", alpha=0.35)
    ax.spines[["top", "right"]].set_visible(False)
axes[0].legend(fontsize=9, frameon=False)
fig.tight_layout()
fig.savefig(os.path.join(OUT, "param-fsm-binary-onehot-cells.svg"))
plt.close(fig)

# ---- figure 2: setup slack and Fmax ----
# required time = 10 ns period - 0.100 ns DFF setup; Tmin = 9.9 - slack
fig, axes = plt.subplots(1, 2, figsize=(9.2, 3.8))
for ax, key, title, fmt in (
    (axes[0], "slack_ns", "最差 setup slack（10 ns 时钟约束，越大越从容）", "{:.2f}"),
    (axes[1], "fmax", "由最差路径推算的最高时钟频率 Fmax", "{:.2f}"),
):
    for i, (enc, (label, color)) in enumerate(ENC_STYLE.items()):
        vals = []
        for n in sizes:
            slack = float(data[enc][n]["slack_ns"])
            v = slack if key == "slack_ns" else 1.0 / (9.9 - slack)
            vals.append(v)
        bars = ax.bar(x + (i - 1) * w, vals, w, label=label, color=color)
        ax.bar_label(bars, fontsize=8, padding=1, fmt=fmt)
    ax.set_title(title, fontsize=11)
    ax.set_xticks(x)
    ax.set_xticklabels([f"{n} 态" for n in sizes])
    ax.set_xlabel("状态数量")
    ax.set_ylabel("ns" if key == "slack_ns" else "GHz")
    ax.grid(axis="y", linestyle="--", alpha=0.35)
    ax.spines[["top", "right"]].set_visible(False)
axes[0].legend(fontsize=9, frameon=False)
fig.tight_layout()
fig.savefig(os.path.join(OUT, "param-fsm-binary-onehot-timing.svg"))
plt.close(fig)

print("wrote:",
      os.path.join(OUT, "param-fsm-binary-onehot-cells.svg"),
      os.path.join(OUT, "param-fsm-binary-onehot-timing.svg"))
