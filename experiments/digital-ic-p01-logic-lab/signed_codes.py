#!/usr/bin/env python3
"""原码、反码、补码三码对照（配套 D004/D005）。

在固定位宽（默认 8 位）下对同一整数给出三种编码，并演示补码如何把
减法统一成加法：a - b 直接按 a + (-b) 的补码相加，丢弃超出位宽的进位。

无参运行对照 +1/-1/+127/-127 并计算 5 - 3；可传入位宽与算例。
"""

import argparse

def mask(width):
    return (1 << width) - 1


def unsigned_bits(value, width):
    return format(value & mask(width), f"0{width}b")


def ones_complement(value, width):
    """反码：负数在原码数值位上逐位取反。"""
    if value >= 0:
        return unsigned_bits(value, width)
    sign_bit = 1 << (width - 1)
    magnitude = (-value) & mask(width - 1)
    return unsigned_bits(sign_bit | (mask(width - 1) ^ magnitude), width)


def sign_magnitude(value, width):
    """原码：最高位符号 + 数值绝对值。"""
    if value >= 0:
        return unsigned_bits(value, width)
    sign_bit = 1 << (width - 1)
    return unsigned_bits(sign_bit | ((-value) & mask(width - 1)), width)


def twos_complement(value, width):
    return unsigned_bits(value, width)


def add_modulo(a, b, width):
    """补码加法：按位宽取模，返回 (截断后的无符号值, 被丢弃的进位)。"""
    raw = (a & mask(width)) + (b & mask(width))
    carry_out = raw >> width
    return raw & mask(width), carry_out


def main():
    parser = argparse.ArgumentParser(description="原码/反码/补码对照与补码减法演示")
    parser.add_argument("--width", type=int, default=8, help="位宽，默认 8")
    parser.add_argument("values", nargs="*", type=int, help="要对照的整数，默认 +1/-1/+127/-127")
    args = parser.parse_args()
    width = args.width
    limit = 1 << (width - 1)
    values = args.values or [1, -1, 127, -127]

    print(f"{width} 位有符号编码对照（合法范围 {-limit} ~ {limit - 1}）")
    print("=" * 60)
    print(f"{'整数':>6} | {'原码':>{width}} | {'反码':>{width}} | {'补码':>{width}}")
    print("-" * 60)
    for value in values:
        if not -limit <= value <= limit - 1:
            print(f"{value:>6} 超出 {width} 位范围，跳过")
            continue
        print(
            f"{value:>6} | {sign_magnitude(value, width):>{width}} | "
            f"{ones_complement(value, width):>{width}} | {twos_complement(value, width):>{width}}"
        )

    print("=" * 60)
    print("补码把减法变加法：计算 5 - 3")
    a, b = 5, 3
    neg_b = -b
    print(f"  3 的补码是 {twos_complement(b, width)}，-3 的补码是 {twos_complement(neg_b, width)}")
    result, carry = add_modulo(a, neg_b, width)
    print(f"  {unsigned_bits(a, width)} + {twos_complement(neg_b, width)} "
          f"= {unsigned_bits(result, width)}，最高位进位 {carry} 直接丢弃")
    print(f"  截断结果按补码解释 = {result if result < limit else result - (1 << width)}")
    print("-" * 60)
    print("结论：同一套加法器无需区分加减，这也是现代芯片几乎只用补码的原因之一。")


if __name__ == "__main__":
    main()
