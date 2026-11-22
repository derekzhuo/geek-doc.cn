#!/usr/bin/env python3
"""8421-BCD 编码与十进制校正加法（配套 D008：BCD 码为什么在钟表和财务芯片里还活着）。

两个核心机制：
  编码：每位十进制数字 0~9 独占 4 个二进制位，位权 8-4-2-1；
        1010~1111 六个码组是非法 BCD 码，解码时直接拒绝。
  加法：按十进制位逐位做 4 位二进制加法，原始和一旦大于 9（或本身产生
        二进制进位），就对该位加 6 修正，低四位留下本位数字，进位 1
        送入下一个十进制位。

无参运行跑四个代表性算例（含 >9 修正与进位传播两个分支），可传入两个
非负十进制整数自行验证。纯标准库，Python 3.8+。
"""

import argparse


def to_bcd(n):
    """非负整数 -> 压缩 8421-BCD 位串，每个十进制数字占 4 位。"""
    if n < 0:
        raise ValueError("BCD 演示只支持非负整数")
    digits = str(n)
    return "".join(format(int(ch), "04b") for ch in digits)


def from_bcd(bits):
    """BCD 位串 -> 整数；任一组 4 位码大于 9 即非法，抛 ValueError。"""
    if len(bits) % 4 != 0:
        raise ValueError("BCD 位串长度必须是 4 的倍数")
    digits = []
    for i in range(0, len(bits), 4):
        nibble = int(bits[i:i + 4], 2)
        if nibble > 9:
            raise ValueError(f"非法 BCD 码组 {bits[i:i + 4]}（值 {nibble} 不在 0~9）")
        digits.append(str(nibble))
    return int("".join(digits)) if digits else 0


def add_nibble(x, y, carry_in=0):
    """单个十进制位的 BCD 加法，返回逐位修正过程。

    返回 dict：raw 原始二进制和、adjusted 加 6 后的和、digit 本位结果、
    carry 向高位的进位、corrected 是否触发修正、reason 触发原因。
    """
    raw = x + y + carry_in
    if raw > 9:
        adjusted = raw + 6
        digit = adjusted & 0xF
        carry_out = adjusted >> 4
        if raw >= 16:
            reason = "原始和已产生二进制进位"
        else:
            reason = "低四位结果落在 10~15，不是合法 BCD 码"
        return {"raw": raw, "adjusted": adjusted, "digit": digit,
                "carry": carry_out, "corrected": True, "reason": reason}
    return {"raw": raw, "adjusted": raw, "digit": raw,
            "carry": 0, "corrected": False, "reason": "结果在 0~9 内，无需修正"}


def bcd_add(a, b):
    """两个非负整数的 BCD 逐位加法，返回 (十进制结果, 逐位过程列表)。"""
    da = [int(ch) for ch in str(a)]
    db = [int(ch) for ch in str(b)]
    width = max(len(da), len(db))
    da = [0] * (width - len(da)) + da
    db = [0] * (width - len(db)) + db

    carry = 0
    steps = []
    result_digits = []
    for pos in range(width - 1, -1, -1):
        trace = add_nibble(da[pos], db[pos], carry)
        steps.append({"position": width - pos, "x": da[pos], "y": db[pos],
                      "carry_in": carry, **trace})
        result_digits.append(str(trace["digit"]))
        carry = trace["carry"]
    if carry:
        result_digits.append(str(carry))
    return int("".join(reversed(result_digits))), steps


def _print_case(a, b):
    print(f"  {a} + {b}")
    print(f"    BCD 编码：{a} -> {to_bcd(a)}，{b} -> {to_bcd(b)}")
    result, steps = bcd_add(a, b)
    for s in steps:
        head = (f"    第 {s['position']} 位：{s['x']}+{s['y']}"
                f"+进位输入 {s['carry_in']} = 原始和 {s['raw']}")
        if s["corrected"]:
            print(head + f"，{s['reason']}，加 6：{s['raw']}+6={s['adjusted']}"
                         f"（本位 {s['digit']}，向高位进 {s['carry']}）")
        else:
            print(head + f"，{s['reason']}，本位 {s['digit']}")
    print(f"    BCD 结果位串：{to_bcd(result)}，十进制结果：{result}")
    assert result == a + b, "BCD 加法结果必须与十进制真值一致"
    print("-" * 64)


def main():
    parser = argparse.ArgumentParser(description="8421-BCD 编码与 +6 校正加法演示")
    parser.add_argument("operands", nargs="*", type=int,
                        help="两个非负十进制加数，默认跑内置算例")
    args = parser.parse_args()

    print("8421-BCD：每位十进制数字占 4 位，非法码组 1010~1111 解码即拒绝")
    print("=" * 64)
    print("编码抽样：")
    for n in (0, 5, 9, 42):
        print(f"  {n:>2} -> {to_bcd(n)}")
    assert from_bcd(to_bcd(42)) == 42
    try:
        from_bcd("1010")
    except ValueError as exc:
        print(f"  解码 1010 -> 拒绝：{exc}")
    print("=" * 64)

    if len(args.operands) == 2:
        cases = [tuple(args.operands)]
    else:
        # 四个代表算例：无需修正 / 10~15 区间修正 / 二进制进位修正 / 多位数进位传播
        cases = [(5, 3), (8, 5), (9, 9), (75, 86)]
    print("BCD 逐位加法（+6 校正）：")
    for a, b in cases:
        if a < 0 or b < 0:
            print(f"加数 {a}/{b} 为负，跳过")
            continue
        _print_case(a, b)
    print("结论：任一位原始和大于 9 或产生进位就加 6，")
    print("      低四位留本位数字、进位 1 送入高位，逐位拼装即得十进制真值。")


if __name__ == "__main__":
    main()
