#!/usr/bin/env python3
"""格雷码的反射构造与相邻性质验证（配套 D009：格雷码为什么相邻值只差 1 位）。

三条主线：
  反射构造：从 1 位序列 [0, 1] 开始，每扩一位把已有序列镜像复制一份，
            正序部分前面补 0、镜像部分前面补 1，递归得到 n 位格雷码。
  性质断言：任意相邻两个码字（含首尾循环相邻）的汉明距离恰为 1；
            反射构造的结果与异或公式 g_i = b_(i+1) XOR b_i 完全一致。
  翻转对照：同一计数周期内普通二进制与格雷码各自的位翻转总量、
            平均每步翻转位数与最坏情况对照。

无参运行跑 1 位到 3 位的构造过程、n=1..8 的性质断言和 n=3/4 的翻转统计，
可传入位宽参数（1..8）自行验证。纯标准库，Python 3.8+。
"""

import argparse


def reflected_gray(width):
    """反射构造法生成 width 位格雷码，返回位串列表（按码字顺序）。"""
    if width < 1:
        raise ValueError("位宽至少为 1")
    sequence = ["0", "1"]
    for _ in range(1, width):
        forward = ["0" + code for code in sequence]
        mirrored = ["1" + code for code in reversed(sequence)]
        sequence = forward + mirrored
    return sequence


def xor_gray(width):
    """异或公式生成 width 位格雷码：g = b ^ (b >> 1)。"""
    return [format(value ^ (value >> 1), f"0{width}b")
            for value in range(1 << width)]


def hamming_distance(a, b):
    """两个等长位串的汉明距离（不同位的个数）。"""
    return sum(bit_a != bit_b for bit_a, bit_b in zip(a, b))


def adjacent_distances(sequence):
    """返回全部循环相邻对的汉明距离，最后一个码字与第一个码字配对。"""
    size = len(sequence)
    return [hamming_distance(sequence[i], sequence[(i + 1) % size])
            for i in range(size)]


def binary_flip_stats(width):
    """普通二进制一个完整计数周期（含 2^n-1 回到 0 的循环步）的翻转统计。"""
    size = 1 << width
    flips = [((value ^ (value + 1)) & (size - 1)).bit_count()
             for value in range(size - 1)]
    flips.append(width)  # 首尾循环：全 1 回到全 0，width 位同时翻转
    return {
        "total": sum(flips),
        "average": sum(flips) / size,
        "worst": max(flips),
        "steps": size,
    }


def gray_flip_stats(width):
    """格雷码一个完整计数周期的翻转统计：每步恰有 1 位翻转。"""
    sequence = reflected_gray(width)
    distances = adjacent_distances(sequence)
    return {
        "total": sum(distances),
        "average": sum(distances) / len(distances),
        "worst": max(distances),
        "steps": len(distances),
    }


def main():
    parser = argparse.ArgumentParser(description="格雷码反射构造与相邻性质验证")
    parser.add_argument("width", nargs="?", type=int, default=3,
                        choices=range(1, 9), help="格雷码位宽，默认 3")
    args = parser.parse_args()

    print("反射构造：镜像复制 + 正序补 0 / 镜像补 1")
    print("=" * 64)
    sequence = ["0", "1"]
    print(f"  1 位：{' '.join(sequence)}")
    for width in range(2, args.width + 1):
        forward = ["0" + code for code in sequence]
        mirrored = ["1" + code for code in reversed(sequence)]
        sequence = forward + mirrored
        print(f"  {width} 位：{' '.join(forward)} | {' '.join(mirrored)}")
    print("=" * 64)

    print("性质断言（n = 1..8 全部成立）：")
    for width in range(1, 9):
        reflected = reflected_gray(width)
        formula = xor_gray(width)
        # 断言 1：反射构造与异或公式给出同一个序列
        assert reflected == formula, f"n={width} 两种构造结果不一致"
        # 断言 2：每个码字只出现一次，2^n 个码组全覆盖
        assert len(set(reflected)) == 1 << width
        # 断言 3：循环相邻（含首尾）汉明距离恰为 1
        distances = adjacent_distances(reflected)
        assert distances == [1] * len(distances), f"n={width} 存在距离不为 1 的相邻对"
        print(f"  n={width}：{1 << width:>3} 个码组，相邻距离 {set(distances)}，"
              f"首尾 {reflected[-1]} -> {reflected[0]} 距离 "
              f"{hamming_distance(reflected[-1], reflected[0])}")
    print("  反射构造 == 异或公式，且任意循环相邻对只差 1 位")
    print("=" * 64)

    print("翻转位数对照（一个完整计数周期，含首尾循环步）：")
    print(f"  {'位宽':<4}{'编码':<8}{'总翻转位数':<12}{'每步平均':<10}{'最坏一步'}")
    for width in (3, 4):
        binary_stats = binary_flip_stats(width)
        gray_stats = gray_flip_stats(width)
        print(f"  n={width:<3}{'二进制':<8}{binary_stats['total']:<14}"
              f"{binary_stats['average']:<12.3f}{binary_stats['worst']} 位")
        print(f"  n={width:<3}{'格雷码':<8}{gray_stats['total']:<14}"
              f"{gray_stats['average']:<12.3f}{gray_stats['worst']} 位")
    print("=" * 64)
    print("结论：反射构造保证每一步（含首尾循环）只有 1 位变化，")
    print("      普通二进制最坏一步要翻 n 位，平均翻转量随位宽趋近每步 2 位。")


if __name__ == "__main__":
    main()
