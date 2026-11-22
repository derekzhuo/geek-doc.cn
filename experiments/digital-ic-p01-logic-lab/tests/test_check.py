#!/usr/bin/env python3
"""P01 逻辑实验包自校验：纯标准库，python3 tests/test_check.py 一键回归。"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import base_convert
import bcd_decimal
import binary_add
import overflow_carry
import quantize
import sign_extend
import signed_codes


def test_quantize():
    assert quantize.decide(0.3) == "0"
    assert quantize.decide(2.9) == "1"
    assert quantize.decide(1.2) == "X"
    assert quantize.decide(quantize.VIL) == "0"
    assert quantize.decide(quantize.VIH) == "1"


def test_base_convert():
    assert base_convert.to_base(200, 2) == "11001000"
    assert base_convert.to_base(200, 16) == "C8"
    assert base_convert.to_base(0, 2) == "0"
    terms, total = base_convert.weight_expansion("11001000")
    assert total == 200 and terms[0] == "1×2^7=128"
    assert [remainder for _, remainder in base_convert.divide_steps(200, 2)] == [0, 0, 0, 1, 0, 0, 1, 1]


def test_binary_add():
    for a, b in [(0, 0), (5, 3), (255, 1), (12, 7)]:
        bits, _ = binary_add.bit_add(a, b)
        result = sum(bit << i for i, bit in enumerate(bits))
        assert result == a + b


def test_signed_codes():
    assert signed_codes.sign_magnitude(-1, 8) == "10000001"
    assert signed_codes.ones_complement(-1, 8) == "11111110"
    assert signed_codes.twos_complement(-1, 8) == "11111111"
    assert signed_codes.twos_complement(-128, 8) == "10000000"
    result, carry = signed_codes.add_modulo(5, -3, 8)  # 5 - 3
    assert result == 2 and carry == 1


def test_sign_extend():
    extended = sign_extend.sign_extend(-5, 8, 16)
    assert format(extended, "016b") == "1111111111111011"
    assert sign_extend.as_signed(extended, 16) == -5
    assert sign_extend.sign_extend(5, 8, 32) == 5
    assert sign_extend.zero_extend_wrong(-5, 8, 16) == 0xFB  # 错误补 0 得到 251


def test_overflow_carry():
    # 7+1：只溢出（正+正变负），无进位
    _, carry, overflow, *_ = overflow_carry.add_with_flags(7, 1, 4)
    assert (carry, overflow) == (0, 1)
    # 8+15：-8 + -1，进位且溢出
    _, carry, overflow, sa, sb, sr = overflow_carry.add_with_flags(8, 15, 4)
    assert (carry, overflow) == (1, 1) and (sa, sb, sr) == (-8, -1, 7)
    # 15+15：-1 + -1 = -2，只进位不溢出
    _, carry, overflow, *_ = overflow_carry.add_with_flags(15, 15, 4)
    assert (carry, overflow) == (1, 0)
    # 2+3：正常，两个标志都没有
    _, carry, overflow, *_ = overflow_carry.add_with_flags(2, 3, 4)
    assert (carry, overflow) == (0, 0)


def test_bcd_decimal():
    # 编码：每位十进制数字独占 4 位
    assert bcd_decimal.to_bcd(0) == "0000"
    assert bcd_decimal.to_bcd(9) == "1001"
    assert bcd_decimal.to_bcd(42) == "01000010"
    assert bcd_decimal.from_bcd("01000010") == 42
    # 1010~1111 是非法 BCD 码组，解码必须拒绝
    for bad in ("1010", "1100", "1111"):
        try:
            bcd_decimal.from_bcd(bad)
            raise AssertionError(f"{bad} 不应被当作合法 BCD 码")
        except ValueError:
            pass

    # 单位加法：5+3 在 0~9 内，不修正
    ok = bcd_decimal.add_nibble(5, 3)
    assert (ok["digit"], ok["carry"], ok["corrected"]) == (8, 0, False)
    # 分支一：8+5=13 落在 10~15，无二进制进位但码组非法，加 6 修正
    branch_a = bcd_decimal.add_nibble(8, 5)
    assert branch_a["corrected"] and branch_a["raw"] == 13
    assert (branch_a["digit"], branch_a["carry"]) == (3, 1)
    # 分支二：9+9=18 本身产生二进制进位，同样加 6
    branch_b = bcd_decimal.add_nibble(9, 9)
    assert branch_b["corrected"] and branch_b["raw"] == 18
    assert (branch_b["digit"], branch_b["carry"]) == (8, 1)

    # 多位数进位传播：个位、十位连续修正，最高位再进 1
    result, steps = bcd_decimal.bcd_add(75, 86)
    assert result == 161
    assert [s["corrected"] for s in steps] == [True, True]
    assert steps[-1]["carry"] == 1

    # 与普通整数加法对拍一组随机形态的取值
    for a, b in [(0, 0), (9, 1), (99, 1), (123, 456), (999, 999)]:
        got, _ = bcd_decimal.bcd_add(a, b)
        assert got == a + b


def main():
    tests = [obj for name, obj in sorted(globals().items()) if name.startswith("test_")]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"\nRESULT: PASS {len(tests)}/{len(tests)}")


if __name__ == "__main__":
    main()
