#!/usr/bin/env python3
"""二进制逐位加法与进位演示（配套 D003：二进制加法为什么逢二进一）。

从最低位开始逐位做 全加：本位和 = a XOR b XOR 进位输入，
进位输出 = (a AND b) OR (进位输入 AND (a XOR b))。
每一位打印进位的产生与传递，最后给出十进制验算。

无参运行计算 0101 + 0011（即 5 + 3），也可传入两个非负整数。
"""

import argparse


def bit_add(a, b):
    """返回 (结果位列表低位在前, 每一拍的描述)。"""
    bits = []
    traces = []
    carry_in = 0
    position = 0
    x = a
    y = b
    while x > 0 or y > 0 or carry_in > 0:
        bit_a = x & 1
        bit_b = y & 1
        bit_sum = bit_a ^ bit_b ^ carry_in
        carry_out = (bit_a & bit_b) | (carry_in & (bit_a ^ bit_b))
        bits.append(bit_sum)
        if bit_a and bit_b:
            reason = "两个 1 相加，产生进位"
        elif carry_in and (bit_a ^ bit_b):
            reason = "进位输入碰到一个 1，向前传递"
        elif carry_in and not bit_a and not bit_b:
            reason = "低位进位在本位落地"
        else:
            reason = "无进位"
        traces.append(
            f"第 {position} 位：{bit_a}+{bit_b}+进位入{carry_in} "
            f"-> 本位 {bit_sum}，进位出 {carry_out}（{reason}）"
        )
        carry_in = carry_out
        x >>= 1
        y >>= 1
        position += 1
    return bits, traces


def main():
    parser = argparse.ArgumentParser(description="二进制逐位加法与进位过程演示")
    parser.add_argument("a", nargs="?", type=int, default=5, help="第一个非负整数")
    parser.add_argument("b", nargs="?", type=int, default=3, help="第二个非负整数")
    args = parser.parse_args()
    if args.a < 0 or args.b < 0:
        raise SystemExit("本脚本只做非负加法，有符号加法请看 signed_codes.py")

    bits, traces = bit_add(args.a, args.b)
    result = sum(bit << i for i, bit in enumerate(bits))

    print(f"计算 {args.a} + {args.b}")
    print("=" * 52)
    for trace in traces:
        print("  " + trace)
    print("-" * 52)
    width = max(len(bits), len(bin(max(args.a, args.b))) - 2)
    fmt = lambda value: format(value, f"0{width}b")
    print(f"  {fmt(args.a)}  ({args.a})")
    print(f"+ {fmt(args.b)}  ({args.b})")
    print(f"  {'-' * width}")
    print(f"  {fmt(result)}  ({result})")
    print("=" * 52)
    print(f"结论：逢二进一，结果 {result}，与十进制 {args.a}+{args.b}={args.a + args.b} 一致")


if __name__ == "__main__":
    main()
