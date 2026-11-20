#!/usr/bin/env python3
"""双阈值判决演示（配套 D001：为什么计算机只认识 0 和 1）。

把连续且带噪声的电压，按 VIL / VIH 两个阈值切成三段：
  电压 <= VIL        -> 合法 0
  VIL < 电压 < VIH   -> 不确定区（判决拒绝）
  电压 >= VIH        -> 合法 1
只要扰动不越过阈值，接收端重新判决得到的逻辑值就不会翻转，这就是噪声容限。

无参运行内置一条受干扰的波形；也可传入自定义电压序列。
"""

import argparse

VIL = 0.8
VIH = 2.0


def decide(voltage):
    if voltage <= VIL:
        return "0"
    if voltage >= VIH:
        return "1"
    return "X"


def quantize(values):
    rows = []
    for v in values:
        level = decide(v)
        if level == "X":
            verdict = "不确定区，本次采样不可信"
        else:
            verdict = f"判决为逻辑 {level}"
        rows.append((v, level, verdict))
    return rows


def main():
    parser = argparse.ArgumentParser(description="双阈值判决与噪声容限演示")
    parser.add_argument(
        "voltages",
        nargs="*",
        type=float,
        help="自定义电压序列（伏特），不传则运行内置受干扰波形",
    )
    args = parser.parse_args()

    values = args.voltages or [0.15, 0.30, 0.72, 1.20, 2.05, 3.10, 2.95, 0.05]
    print(f"阈值：VIL={VIL} V，VIH={VIH} V；区间 [VIL, VIH] 为不确定区")
    print("-" * 52)
    for v, level, verdict in quantize(values):
        print(f"电压 {v:5.2f} V -> {level}  {verdict}")
    print("-" * 52)
    print("观察：0.15/0.30/0.72 这些带扰动的低电平都稳定判 0，")
    print("      2.95/3.10 等带扰动的高电平都稳定判 1，干扰没有翻案。")


if __name__ == "__main__":
    main()
