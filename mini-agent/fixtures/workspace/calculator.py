"""示例计算器模块（含一处待修复的缺陷）。"""


def square(n):
    # BUG：误用加法，平方应为乘法
    return n + n
