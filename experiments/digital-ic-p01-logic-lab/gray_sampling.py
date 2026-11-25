#!/usr/bin/env python3
"""比较多位二进制与格雷码在逐位到达延迟下的采样结果（配套 D010）。

这是确定性的位偏斜模型，不模拟模拟电路的亚稳态。每一位在自己的到达
时刻从旧值变为新值；采样时，已经到达的位取新值，其余位保留旧值。
纯标准库，Python 3.8+。
"""

import argparse


def gray_encode(value):
    """把非负整数转换为反射格雷码对应的整数值。"""
    if value < 0:
        raise ValueError("value 必须是非负整数")
    return value ^ (value >> 1)


def changed_bits(old, new):
    """返回发生变化的位号，最低位编号为 0。"""
    difference = old ^ new
    return [bit for bit in range(max(old, new, 1).bit_length())
            if difference & (1 << bit)]


def sample_with_skew(old, new, delays, sample_time):
    """按每一位的到达延迟计算采样值；到达时刻当次采样即取新值。"""
    if min(old, new, sample_time) < 0:
        raise ValueError("数值与采样时刻都不能为负")
    width = len(delays)
    if width == 0 or old >= (1 << width) or new >= (1 << width):
        raise ValueError("delays 的位数必须容纳旧值与新值")
    if any(delay < 0 for delay in delays):
        raise ValueError("delays 必须给每一位一个非负到达时刻")
    sampled = 0
    for bit, delay in enumerate(delays):
        source = new if sample_time >= delay else old
        sampled |= ((source >> bit) & 1) << bit
    return sampled


def main():
    parser = argparse.ArgumentParser(description="二进制与格雷码的位偏斜采样对照")
    parser.add_argument("--width", type=int, default=4, choices=range(2, 9),
                        help="总线位宽，默认 4")
    args = parser.parse_args()

    old, new = 3, 4
    mask = (1 << args.width) - 1
    gray_old, gray_new = gray_encode(old) & mask, gray_encode(new) & mask
    delays = [float(bit + 1) for bit in range(args.width)]
    sample_times = [0.5, 1.5, 2.5, 3.5]

    print(f"位宽：{args.width}；二进制计数：{old} -> {new}")
    print(f"二进制：{old:0{args.width}b} -> {new:0{args.width}b}，"
          f"变化位 {changed_bits(old, new)}")
    print(f"格雷码：{gray_old:0{args.width}b} -> {gray_new:0{args.width}b}，"
          f"变化位 {changed_bits(gray_old, gray_new)}")
    print("每一位在时刻 1、2、3……依次到达；表中整数为采样结果。")
    print(f"  {'采样时刻':<10}{'二进制':<12}{'格雷码':<12}")
    binary_samples = []
    gray_samples = []
    for sample_time in sample_times:
        binary_sample = sample_with_skew(old, new, delays, sample_time)
        gray_sample = sample_with_skew(gray_old, gray_new, delays, sample_time)
        binary_samples.append(binary_sample)
        gray_samples.append(gray_sample)
        print(f"  {sample_time:<10.1f}{binary_sample:<12}{gray_sample:<12}")

    assert binary_samples == [3, 2, 0, 4]
    assert 0 not in (old, new)
    assert all(sample in (gray_old, gray_new) for sample in gray_samples)
    print("结论：二进制采到了既非旧值也非新值的 0；格雷码只出现旧值或新值。")

    jump_a, jump_b = 0, 2
    jump_bits = changed_bits(gray_encode(jump_a), gray_encode(jump_b))
    print(f"非连续跳变反例：数值 {jump_a} -> {jump_b} 的格雷码 "
          f"{gray_encode(jump_a):03b} -> {gray_encode(jump_b):03b}，"
          f"变化位 {jump_bits}，不再满足单比特变化。")
    print("注意：本模型只展示位偏斜，不证明跨时钟域无需同步器。")


if __name__ == "__main__":
    main()
