#!/usr/bin/env python3
"""Plot the measured leaf-cell counts produced by scripts/qor.py."""
import argparse
import collections
import json
import re
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib import font_manager


def counts(path, top):
    document = json.loads(Path(path).read_text(encoding="utf-8"))
    modules = document["modules"]
    result = collections.Counter()

    def walk(name):
        for cell in modules[name].get("cells", {}).values():
            cell_type = cell["type"]
            if cell_type in modules:
                walk(cell_type)
            else:
                result[cell_type] += 1

    walk(top)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--build", default="build")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    designs = ["arbiter4", "counter8", "hier_alu"]
    logic = []
    registers = []
    for design in designs:
        values = counts(Path(args.build) / f"{design}.json", design)
        sequential = sum(count for name, count in values.items()
                         if re.match(r"^\$[a-z]*(?:dff|dlatch|latch)", name))
        registers.append(sequential)
        logic.append(sum(values.values()) - sequential)

    for candidate in ["PingFang SC", "Noto Sans CJK SC", "Arial Unicode MS"]:
        if any(font.name == candidate for font in font_manager.fontManager.ttflist):
            plt.rcParams["font.sans-serif"] = [candidate]
            break
    plt.rcParams["axes.unicode_minus"] = False
    fig, ax = plt.subplots(figsize=(8.2, 4.8))
    x = range(len(designs))
    ax.bar(x, logic, width=0.56, label="组合/算术叶单元", color="#2C7BE5")
    ax.bar(x, registers, width=0.56, bottom=logic, label="时序叶单元", color="#E08A1E")
    for index, (comb, seq) in enumerate(zip(logic, registers)):
        ax.text(index, comb / 2 if comb else 0.15, str(comb), ha="center", va="center", color="white" if comb else "#27364B")
        if seq:
            ax.text(index, comb + seq / 2, str(seq), ha="center", va="center", color="white")
        ax.text(index, comb + seq + 0.25, f"合计 {comb + seq}", ha="center", color="#27364B")
    ax.set_xticks(list(x), ["arbiter4\n纯组合", "counter8\n时序", "hier_alu\n层次展开"])
    ax.set_ylabel("RTLIL 叶单元数（个）")
    ax.set_title("同一 proc + opt 阶段，三种结构的叶单元构成")
    ax.set_ylim(0, 12)
    ax.grid(axis="y", alpha=0.2)
    ax.legend(frameon=False, loc="upper right")
    fig.text(0.1, 0.01, "来源：Yosys 0.33 write_json 实测；层次实例递归展开，不把实例本身计为叶单元。", fontsize=9, color="#5B6B8C")
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(args.output, format="svg")


if __name__ == "__main__":
    main()
