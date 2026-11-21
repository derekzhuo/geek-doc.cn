#!/usr/bin/env python3
"""Count leaf RTLIL cells from Yosys JSON and compare with stat -json."""
import argparse
import collections
import json
import re
import sys


def count_from_top(document, top):
    modules = document["modules"]
    totals = collections.Counter()
    instances = collections.Counter()
    visited = set()

    def walk(module_name):
        if module_name not in modules:
            raise KeyError(f"missing module: {module_name}")
        for cell_name, cell in modules[module_name].get("cells", {}).items():
            cell_type = cell["type"]
            if cell_type in modules:
                instances[cell_type] += 1
                walk(cell_type)
            else:
                totals[cell_type] += 1
        visited.add(module_name)

    walk(top)
    return totals, instances, visited


def stat_counts(document, top):
    """Read Yosys 0.33 stat -json format; tolerate numeric and dict fields."""
    modules = document["modules"]
    top_data = modules.get(top) or modules.get("\\" + top)
    if top_data is None:
        raise KeyError(f"missing stat module: {top}")
    return collections.Counter(top_data.get("num_cells_by_type", {}))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", required=True)
    parser.add_argument("--stat-json", required=True)
    parser.add_argument("--top", required=True)
    args = parser.parse_args()

    with open(args.json, encoding="utf-8") as stream:
        document = json.load(stream)
    with open(args.stat_json, encoding="utf-8") as stream:
        stat_document = json.load(stream)

    totals, instances, visited = count_from_top(document, args.top)
    direct_stat = stat_counts(stat_document, args.top)
    direct_json = collections.Counter(
        cell["type"]
        for cell in document["modules"][args.top].get("cells", {}).values()
    )
    if direct_json != direct_stat:
        print(f"MISMATCH {args.top}: JSON={dict(direct_json)} stat={dict(direct_stat)}")
        return 1

    leaf_total = sum(totals.values())
    sequential = sum(
        count for cell_type, count in totals.items()
        if re.match(r"^\$[a-z]*(?:dff|dlatch|latch)", cell_type)
    )
    print(f"TOP {args.top}")
    top_module = document["modules"][args.top]
    print(f"ports={len(top_module.get('ports', {}))} netnames={len(top_module.get('netnames', {}))}")
    print(f"modules_reached={len(visited)} hierarchical_instances={sum(instances.values())}")
    print(f"direct_cells={sum(direct_json.values())} leaf_cells={leaf_total} sequential_cells={sequential}")
    print("direct_stat_match=PASS")
    for cell_type, count in sorted(totals.items()):
        print(f"leaf {cell_type} {count}")
    for cell_type, count in sorted(instances.items()):
        print(f"instance {cell_type} {count}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
