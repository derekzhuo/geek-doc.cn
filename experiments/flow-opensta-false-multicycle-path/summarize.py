#!/usr/bin/env python3
"""Extract measured setup/hold slack from the three OpenSTA reports."""
from pathlib import Path
import re
import sys

out_dir = Path(sys.argv[1])
out_file = Path(sys.argv[2])
sections = {
    "DATA SETUP": "data_setup",
    "DATA HOLD": "data_hold",
    "CONFIG SETUP": "config_setup",
    "CONFIG HOLD": "config_hold",
}
lines = [
    "OpenSTA exception-path comparison (ns)",
    "stage,data_setup,data_hold,config_setup,config_hold",
]
for stage in ("baseline", "false_path", "multicycle"):
    text = (out_dir / f"{stage}.log").read_text()
    values = {}
    for heading, key in sections.items():
        match = re.search(
            rf"=+ {re.escape(heading)} =+\n(.*?)(?=\n=+|\Z)", text, re.S
        )
        if not match:
            raise RuntimeError(f"missing section {heading} in {stage}")
        block = match.group(1)
        if "No paths found" in block:
            values[key] = "removed"
        else:
            slack = re.search(r"([+-]?\d+\.\d+)\s+slack\s+\((MET|VIOLATED)\)", block)
            if not slack:
                raise RuntimeError(f"missing slack in {stage}/{heading}")
            values[key] = f"{slack.group(1)} {slack.group(2)}"
    lines.append(stage + "," + ",".join(values[key] for key in sections.values()))
out_file.write_text("\n".join(lines) + "\n")
