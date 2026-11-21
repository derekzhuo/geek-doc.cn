#!/usr/bin/env python3
import argparse
import csv
import hashlib
import json
import re
from pathlib import Path


def last_match(pattern, text, flags=0):
    matches = re.findall(pattern, text, flags)
    return matches[-1] if matches else None


def utilisation(text, name):
    match = last_match(
        rf"Info:\s+{re.escape(name)}:\s+(\d+)/\s*(\d+)\s+(\d+)%", text
    )
    if not match:
        return None, None, None
    return int(match[0]), int(match[1]), int(match[2])


def parse_seed(results_dir, seed):
    log_path = results_dir / f"nextpnr-seed-{seed}.log"
    text = log_path.read_text(encoding="utf-8")
    status_matches = re.findall(r"nextpnr exit code:\s*(\d+)", text)
    status = int(status_matches[-1]) if status_matches else None
    fmax_matches = re.findall(
        r"Max frequency for clock '[^']+':\s*([0-9.]+) MHz \((PASS|FAIL) at ([0-9.]+) MHz\)",
        text,
    )
    fmax = fmax_matches[-1] if fmax_matches else None
    placement_fmax = fmax_matches[0] if fmax_matches else None
    delay = last_match(r"Max delay\s+[^:]+:\s*([0-9.]+) ns", text)
    path_matches = re.findall(r"Info: ([0-9.]+) ns logic, ([0-9.]+) ns routing", text)
    path = path_matches[0] if path_matches else None
    routing_arcs = last_match(r"Info: Routing (\d+) arcs\.", text)
    router_row = last_match(
        r"Info:\s+(\d+)\s+\|\s+(\d+)\s+(\d+)\s+\|\s+(\d+)\s+(\d+)\s+\|\s+(\d+)\|\s+([0-9.]+)\s+([0-9.]+)\|",
        text,
    )
    lc_used, lc_total, lc_pct = utilisation(text, "ICESTORM_LC")
    io_used, io_total, io_pct = utilisation(text, "SB_IO")
    gb_used, gb_total, gb_pct = utilisation(text, "SB_GB")
    asc_path = results_dir / f"top-seed-{seed}.asc"
    asc_data = asc_path.read_bytes() if asc_path.exists() else b""
    return {
        "seed": seed,
        "exit_code": status,
        "finished_normally": "Info: Program finished normally." in text,
        "target_mhz": float(fmax[2]) if fmax else None,
        "placement_fmax_mhz": float(placement_fmax[0]) if placement_fmax else None,
        "fmax_mhz": float(fmax[0]) if fmax else None,
        "timing_result": fmax[1] if fmax else None,
        "max_delay_ns": float(delay) if delay else None,
        "critical_logic_ns": float(path[0]) if path else None,
        "critical_routing_ns": float(path[1]) if path else None,
        "routing_arcs": int(routing_arcs) if routing_arcs else None,
        "router_iterations": int(router_row[0]) if router_row else None,
        "ripup_arcs": int(router_row[1]) if router_row else None,
        "rerouted_without_ripup": int(router_row[2]) if router_row else None,
        "remaining_arcs": int(router_row[5]) if router_row else None,
        "router_seconds": float(router_row[7]) if router_row else None,
        "lc_used": lc_used,
        "lc_total": lc_total,
        "lc_pct": lc_pct,
        "io_used": io_used,
        "io_total": io_total,
        "io_pct": io_pct,
        "gb_used": gb_used,
        "gb_total": gb_total,
        "gb_pct": gb_pct,
        "warnings": len(re.findall(r"^Warning:", text, re.MULTILINE)),
        "errors": len(re.findall(r"^ERROR:", text, re.MULTILINE)),
        "asc_bytes": len(asc_data) if asc_data else None,
        "asc_sha256": hashlib.sha256(asc_data).hexdigest() if asc_data else None,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", type=Path, required=True)
    parser.add_argument("--csv", type=Path, required=True)
    parser.add_argument("--json", type=Path, required=True)
    args = parser.parse_args()

    rows = [parse_seed(args.results, seed) for seed in range(5)]
    fields = list(rows[0])
    with args.csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    args.json.write_text(json.dumps(rows, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
