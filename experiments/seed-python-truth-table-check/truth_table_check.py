#!/usr/bin/env python3
"""用独立最小项需求验证三变量布尔表达式。"""

from itertools import product
import warnings

VARIABLES = ("A", "B", "C")
MIN_TERMS = frozenset({1, 2, 3, 5, 7})


def minterm_index(values):
    """按 A、B、C 顺序把一行输入转换为最小项编号。"""
    a, b, c = values
    return (int(a) << 2) | (int(b) << 1) | int(c)


def required(values):
    """需求参考函数：只依据独立最小项集合，不复用待测表达式。"""
    return minterm_index(values) in MIN_TERMS


def wrong(values):
    """手算误写：C + 非A非B。"""
    a, b, c = values
    return c or (not a and not b)


def corrected(values):
    """修正：C + 非AB。"""
    a, b, c = values
    return c or (not a and b)


def rows():
    """固定为 A 外循环、C 内循环，对应 m0 到 m7。"""
    return product((False, True), repeat=len(VARIABLES))


def check(candidate, care=None):
    """只比较 care 指定的行；失败立即报告按变量顺序遇到的首个反例。"""
    compared = 0
    for values in rows():
        index = minterm_index(values)
        if care is not None and index not in care:
            continue
        compared += 1
        expected = required(values)
        actual = candidate(values)
        if actual != expected:
            return {
                "passed": False,
                "compared": compared,
                "index": index,
                "values": values,
                "expected": expected,
                "actual": actual,
            }
    return {"passed": True, "compared": compared}


def report(name, result):
    if result["passed"]:
        print(f"PASS {name}: compared={result['compared']}, mismatches=0")
        return
    bits = "".join(str(int(value)) for value in result["values"])
    print(
        f"FAIL {name}: first counterexample=m{result['index']}, "
        f"ABC={bits}, expected={int(result['expected'])}, "
        f"actual={int(result['actual'])}"
    )


def main():
    print("Requirement: F(A,B,C)=sum_m(1,2,3,5,7); variable order=A,B,C")
    print("Reference truth table: minterm ABC F")
    for values in rows():
        bits = "".join(str(int(value)) for value in values)
        print(f"  m{minterm_index(values)} {bits} {int(required(values))}")
    wrong_result = check(wrong)
    report("C OR ((NOT A) AND (NOT B))", wrong_result)

    corrected_result = check(corrected)
    report("C OR ((NOT A) AND B)", corrected_result)

    care_result = check(wrong, care={1, 2, 3, 4, 5, 6, 7})
    report("wrong expression with m0 independently excluded", care_result)

    with warnings.catch_warnings():
        warnings.simplefilter("ignore", DeprecationWarning)
        inverted_true = ~True
    print(f"Boolean-not-bitwise trap: not True={not True}, ~True={inverted_true}")
    print(f"Boolean-and-bitwise difference: True & True={True & True}, True and True={True and True}")

    # 自校验：误写式在 m0、m2 不同；修正后八行必须全部通过；无关项不能替代全量证明。
    assert [minterm_index(values) for values in rows()
            if wrong(values) != required(values)] == [0, 2]
    assert corrected_result["passed"] and corrected_result["compared"] == 8
    assert not care_result["passed"] and care_result["index"] == 2
    assert inverted_true == -2
    print("SELF-CHECK PASS: wrong mismatch set={m0,m2}; corrected full table=8/8")


if __name__ == "__main__":
    main()
