#!/usr/bin/env python3
"""进位与溢出对照（配套 D007：溢出和进位是一回事吗）。

同一次二进制加法，从两种数制解释会得到两个独立标志：
  进位 C（无符号视角）：结果超出 2^位宽，最高位向外产生进位即置 1。
  溢出 V（有符号视角）：两个同号数相加，结果符号被翻转即置 1；
                        等价判据是最高位的进位输入与进位输出不相等。

无参运行在 4 位补码下跑四个代表性算例，可传入位宽与两个加数自行验证。
"""

import argparse


def add_with_flags(a, b, width):
    cap = 1 << width
    raw = a + b
    carry = 1 if raw >= cap or raw < 0 else 0
    wrapped = raw % cap

    # 有符号解释
    sign_bit = 1 << (width - 1)
    sa = a - cap if a & sign_bit else a
    sb = b - cap if b & sign_bit else b
    sr = wrapped - cap if wrapped & sign_bit else wrapped
    overflow = 1 if (sa >= 0 and sb >= 0 and sr < 0) or (sa < 0 and sb < 0 and sr >= 0) else 0
    return wrapped, carry, overflow, sa, sb, sr


def main():
    parser = argparse.ArgumentParser(description="进位 C 与溢出 V 标志对照演示")
    parser.add_argument("--width", type=int, default=4, help="补码位宽，默认 4")
    parser.add_argument("operands", nargs="*", type=int,
                        help="两个加数（按位宽补码表示的无符号位模式），默认跑内置算例")
    args = parser.parse_args()
    width = args.width
    cap = 1 << width

    if len(args.operands) == 2:
        cases = [tuple(args.operands)]
    else:
        # 4 位代表算例，覆盖 C/V 的四种组合：
        # 7+1 只溢出、8+15 进位且溢出、15+15 只进位、2+3 都没有
        cases = [(7, 1), (8, 15), (15, 15), (2, 3)]

    print(f"{width} 位补码加法：进位 C 与溢出 V 对照（有符号范围 {-cap // 2} ~ {cap // 2 - 1}）")
    print("=" * 64)
    for a, b in cases:
        if not 0 <= a < cap or not 0 <= b < cap:
            print(f"加数 {a}/{b} 超出 {width} 位位模式范围，跳过")
            continue
        wrapped, carry, overflow, sa, sb, sr = add_with_flags(a, b, width)
        print(f"  {format(a, f'0{width}b')} + {format(b, f'0{width}b')} = {format(wrapped, f'0{width}b')}")
        print(f"    无符号：{a}+{b}={a + b}，进位 C={carry}"
              + (f"，截断后为 {wrapped}" if carry else ""))
        print(f"    有符号：{sa}+{sb}，结果解释为 {sr}，溢出 V={overflow}")
        print("-" * 64)
    print("结论：C 管无符号是否超量程，V 管有符号结果是否失真，")
    print("      二者可以单独出现、同时出现或都不出现，不是同一个标志。")


if __name__ == "__main__":
    main()
