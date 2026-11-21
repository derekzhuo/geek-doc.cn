#!/usr/bin/env python3
import argparse
import csv

import matplotlib.pyplot as plt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    with open(args.csv, newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    seeds = [int(row["seed"]) for row in rows]
    fmax = [float(row["fmax_mhz"]) for row in rows]
    ripup = [int(row["ripup_arcs"]) for row in rows]
    target = float(rows[0]["target_mhz"])

    plt.rcParams.update({
        "font.sans-serif": ["PingFang SC", "Hiragino Sans GB", "Arial Unicode MS", "DejaVu Sans"],
        "axes.unicode_minus": False,
        "font.size": 10,
    })
    fig, (ax_fmax, ax_route) = plt.subplots(
        2, 1, figsize=(8.2, 6.0), gridspec_kw={"height_ratios": [3, 1]}
    )
    bars = ax_fmax.bar(seeds, fmax, width=0.58, color="#2C7BE5")
    ax_fmax.axhline(target, color="#D9534F", linestyle="--", linewidth=1.5,
                    label=f"时序目标 {target:.0f} MHz")
    ax_fmax.set_title("nextpnr-iCE40 五轮布局种子扫描：最终 Fmax 与拆线重绕")
    ax_fmax.set_ylabel("布线后最高频率（MHz）")
    ax_fmax.set_xticks(seeds, [f"seed {seed}" for seed in seeds])
    ax_fmax.set_ylim(0, 220)
    ax_fmax.grid(axis="y", alpha=0.2)
    ax_fmax.legend(loc="lower right")
    for bar, value in zip(bars, fmax):
        ax_fmax.text(bar.get_x() + bar.get_width() / 2, value + 4,
                     f"{value:.2f}", ha="center", color="#1F2D3D")

    route_colors = ["#E08A1E" if value else "#2E9E6B" for value in ripup]
    ax_route.bar(seeds, ripup, width=0.58, color=route_colors)
    ax_route.set_ylabel("拆线重绕弧数")
    ax_route.set_xlabel("唯一变量：nextpnr --seed")
    ax_route.set_xticks(seeds, [str(seed) for seed in seeds])
    ax_route.set_yticks([0, 1])
    ax_route.set_ylim(0, 1.35)
    ax_route.grid(axis="y", alpha=0.2)
    for seed, value in zip(seeds, ripup):
        ax_route.text(seed, value + 0.05, str(value), ha="center", color="#1F2D3D")

    fig.text(0.5, 0.005,
             "固定 JSON（SHA-256 44e1e58a…）、HX1K-TQ144、PCF 与 50 MHz 目标；数据源：五份 nextpnr 完整日志",
             ha="center", fontsize=9, color="#5B6B8C")
    fig.tight_layout(rect=[0, 0.035, 1, 1])
    fig.savefig(args.output, format="svg", bbox_inches="tight")


if __name__ == "__main__":
    main()
