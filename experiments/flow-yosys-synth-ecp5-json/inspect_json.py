#!/usr/bin/env python3
import json
from collections import Counter
from pathlib import Path

BUILD = Path("build")
RESULTS = Path("results")
RESULTS.mkdir(exist_ok=True)

for family in ("early", "ice40", "ecp5"):
    path = BUILD / f"{family}.json"
    doc = json.loads(path.read_text())
    top = doc["modules"]["accumulator"]
    counts = Counter(cell["type"] for cell in top["cells"].values())
    print(f"[{family}] creator={doc['creator']}")
    print(f"top cells={len(top['cells'])} ports={len(top['ports'])} netnames={len(top['netnames'])}")
    for cell_type, amount in sorted(counts.items()):
        print(f"  {cell_type}: {amount}")
    excerpt = {
        "creator": doc["creator"],
        "module": "accumulator",
        "ports": top["ports"],
        "cell_type_counts": dict(sorted(counts.items())),
        "first_cells": dict(list(top["cells"].items())[:2]),
    }
    (RESULTS / f"{family}-excerpt.json").write_text(
        json.dumps(excerpt, indent=2, ensure_ascii=False) + "\n"
    )
