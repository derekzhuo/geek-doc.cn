#!/usr/bin/env python3
"""覆盖率阈值检查：解析 coverage.dat 里的 v_line 计数点，计算行覆盖百分比。

用法：coverage_gate.py <dat文件> <阈值百分比>
行覆盖 >= 阈值打印 PASS 并以 0 退出，否则打印 FAIL 并以 1 退出。
CI 里直接把这行的退出码接进门禁即可。
"""
import sys


def line_coverage(dat_path):
    total = 0
    covered = 0
    with open(dat_path, "rb") as f:
        for raw in f:
            if not raw.startswith(b"C "):
                continue
            # 字段用 0x02 分隔，page 字段形如 v_line/counter
            fields = raw.split(b"\x02")
            page = b""
            for i, field in enumerate(fields):
                if field.endswith(b"page") and i + 1 < len(fields):
                    page = fields[i + 1]
                    break
            if not page.startswith(b"v_line"):
                continue
            count = int(raw.rstrip().rsplit(b" ", 1)[1])
            total += 1
            if count > 0:
                covered += 1
    return covered, total


def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <coverage.dat> <threshold pct>", file=sys.stderr)
        return 2
    covered, total = line_coverage(sys.argv[1])
    threshold = float(sys.argv[2])
    pct = 100.0 * covered / total if total else 0.0
    verdict = "PASS" if pct >= threshold else "FAIL"
    print(f"coverage_gate: v_line {covered}/{total} = {pct:.1f}% "
          f"vs threshold {threshold:.1f}% -> {verdict}")
    return 0 if verdict == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
