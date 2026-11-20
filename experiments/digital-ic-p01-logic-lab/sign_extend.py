#!/usr/bin/env python3
"""符号扩展演示（配套 D006：补码的符号扩展为什么直接复制符号位）。

把一个补码整数从窄位宽扩展到宽位宽：新增的高位全部填原最高位（符号位）。
正数补 0、负数补 1，扩展前后按补码解释的值保持不变；错误地补 0 会改变负数的值。

无参运行演示 8 -> 16 -> 32 位的 +5 与 -5，并对照错误补 0 的结果。
"""

import argparse


def sign_extend(value, from_width, to_width):
    if to_width < from_width:
        raise ValueError("目标位宽必须不小于原位宽")
    narrow = value & ((1 << from_width) - 1)
    sign_bit = 1 << (from_width - 1)
    if narrow & sign_bit:  # 符号位为 1（负数），高位补 1
        upper_mask = ((1 << to_width) - 1) ^ ((1 << from_width) - 1)
        return narrow | upper_mask
    return narrow  # 正数高位补 0


def as_signed(value, width):
    sign_bit = 1 << (width - 1)
    return value - (1 << width) if value & sign_bit else value


def zero_extend_wrong(value, from_width, to_width):
    """错误示范：负数高位补 0。"""
    return value & ((1 << from_width) - 1)


def main():
    parser = argparse.ArgumentParser(description="补码符号扩展演示")
    parser.add_argument("value", nargs="?", type=int, default=-5, help="要扩展的补码整数，默认 -5")
    args = parser.parse_args()

    value = args.value
    print(f"整数 {value} 的符号扩展过程")
    print("=" * 60)
    for width in (8, 16, 32):
        if not -(1 << (width - 1)) <= value <= (1 << (width - 1)) - 1:
            print(f"{width} 位装不下该值，跳过")
            continue
        encoded = value & ((1 << width) - 1)
        print(f"{width:2d} 位：{format(encoded, f'0{width}b')}  按补码解释 = {as_signed(encoded, width)}")

    print("-" * 60)
    narrow = value & 0xFF
    correct = sign_extend(value, 8, 16)
    wrong = zero_extend_wrong(value, 8, 16)
    print(f"正确：复制符号位 -> {format(correct, '016b')}，解释 = {as_signed(correct, 16)}")
    print(f"错误：高位补 0   -> {format(wrong, '016b')}，解释 = {wrong}（值被改变）")
    print("=" * 60)
    print("结论：符号扩展只复制符号位，位数变宽而数值不变；负数补 0 会被误读成大正数。")


if __name__ == "__main__":
    main()
