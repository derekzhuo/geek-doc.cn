#!/usr/bin/env python3
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
lines = ["scenario,check,arrival_ns,required_ns,slack_ns,status"]
for scenario in ("baseline", "dual_edge"):
    text = (src / f"{scenario}.log").read_text()
    for check in ("RX SETUP", "RX HOLD", "TX SETUP", "TX HOLD"):
        block = text.split(f"================ {check} ================", 1)[1]
        block = block.split("================", 1)[0]
        arrival = re.search(r"^\s*(-?\d+\.\d+)\s+data arrival time", block, re.MULTILINE)
        required = re.search(r"^\s*(-?\d+\.\d+)\s+data required time", block, re.MULTILINE)
        slack = re.search(r"slack \((MET|VIOLATED)\)\s+(-?\d+\.\d+)|(-?\d+\.\d+)\s+slack \((MET|VIOLATED)\)", block)
        if not (arrival and required and slack):
            raise SystemExit(f"cannot parse {scenario} {check}")
        if slack.group(1):
            status, value = slack.group(1), slack.group(2)
        else:
            value, status = slack.group(3), slack.group(4)
        lines.append(f"{scenario},{check},{arrival.group(1)},{required.group(1)},{value},{status}")
out.write_text("\n".join(lines) + "\n")
