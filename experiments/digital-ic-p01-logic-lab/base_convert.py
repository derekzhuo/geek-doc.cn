#!/usr/bin/env python3
"""进制转换演示（配套 D002：二进制、十进制、十六进制怎样互相换算）。

无参运行打印整数 200 在二/十/十六进制下的完整推导：
  十进制 -> 二进制：除 2 取余，逆序排列
  十进制 -> 十六进制：除 16 取余，逆序排列
  二进制 -> 十进制：按位权展开求和
也可传入任意非负整数与目标进制（2 或 16）。
"""

import argparse

HEX_DIGITS = "0123456789ABCDEF"


def divide_steps(number, base):
    """返回除基取余过程的 (商, 余数) 序列，余数按产生顺序（低位在前）。"""
    steps = []
    n = number
    if n == 0:
        return [(0, 0)]
    while n > 0:
        steps.append((n // base, n % base))
        n //= base
    return steps


def to_base(number, base):
    if number == 0:
        return "0"
    digits = []
    for _, remainder in divide_steps(number, base):
        digits.append(HEX_DIGITS[remainder] if base == 16 else str(remainder))
    return "".join(reversed(digits))


def weight_expansion(bits):
    """二进制字符串按位权展开，返回 (项描述列表, 十进制和)。"""
    terms = []
    total = 0
    width = len(bits)
    for i, bit in enumerate(bits):
        power = width - 1 - i
        if bit == "1":
            value = 2 ** power
            total += value
            terms.append(f"1×2^{power}={value}")
    return terms, total


def main():
    parser = argparse.ArgumentParser(description="二/十/十六进制换算过程演示")
    parser.add_argument("number", nargs="?", type=int, default=200, help="待转换的十进制非负整数")
    parser.add_argument("--base", type=int, choices=[2, 16], default=2, help="目标进制，默认 2")
    args = parser.parse_args()
    if args.number < 0:
        raise SystemExit("本脚本只处理非负整数，有符号编码请看 signed_codes.py")

    n = args.number
    print(f"整数 {n} 的进制换算")
    print("=" * 52)
    print(f"[除 {args.base} 取余]  每一步：当前数 -> (商, 余数)")
    for quotient, remainder in divide_steps(n, args.base):
        rem_text = HEX_DIGITS[remainder] if args.base == 16 else str(remainder)
        print(f"  {quotient * args.base + remainder:4d} -> 商 {quotient:4d}，余数 {rem_text}")
    print(f"余数逆序排列 => {to_base(n, args.base)}（{args.base} 进制）")

    binary = to_base(n, 2)
    print("-" * 52)
    print(f"[位权展开验证] 二进制 {binary}")
    terms, total = weight_expansion(binary)
    print("  " + " + ".join(terms))
    print(f"  = {total}（十进制）")
    print("-" * 52)
    print(f"结论：二进制 {binary} = 十进制 {n} = 十六进制 0x{to_base(n, 16)}")


if __name__ == "__main__":
    main()
