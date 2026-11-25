#!/usr/bin/env python3
import csv
import json
import random
import re
import statistics
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"
DECKS = RESULTS / "decks"
LOGS = RESULTS / "ngspice"
SEED = 20261126
RUNS = 50
NOMINAL_OHM = 10_000.0
TOLERANCE = 0.05


def simulate(template, kind, case, r1, r2):
    deck = DECKS / f"{case}.cir"
    deck.write_text(template.replace("__R1__", f"{r1:.12f}").replace("__R2__", f"{r2:.12f}"), encoding="utf-8")
    command = ["ngspice", "-b", str(deck.relative_to(ROOT))]
    completed = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    log_path = LOGS / f"{case}.log"
    log_path.write_text(completed.stdout, encoding="utf-8")
    matches = re.findall(r"v\(out\)\s*=\s*([-+0-9.eE]+)", completed.stdout)
    if completed.returncode != 0 or len(matches) != 1:
        raise RuntimeError(f"{case}: exit={completed.returncode}, measurements={len(matches)}; see {log_path}")
    vout = float(matches[0])
    print(f"CASE_RESULT kind={kind} case={case} r1_ohm={r1:.12f} r2_ohm={r2:.12f} vout={vout:.12f} exit={completed.returncode}")
    return {"kind": kind, "case": case, "seed": SEED if kind == "monte_carlo" else "", "r1_ohm": f"{r1:.12f}", "r2_ohm": f"{r2:.12f}", "vout": f"{vout:.12f}", "exit_code": completed.returncode}


def main():
    DECKS.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    template = (ROOT / "divider.cir.tmpl").read_text(encoding="utf-8")
    rows = [simulate(template, "deterministic", "nominal", NOMINAL_OHM, NOMINAL_OHM)]
    rows.append(simulate(template, "deterministic", "r1_high_r2_low", NOMINAL_OHM * 1.05, NOMINAL_OHM * 0.95))
    rows.append(simulate(template, "deterministic", "r1_low_r2_high", NOMINAL_OHM * 0.95, NOMINAL_OHM * 1.05))

    rng = random.Random(SEED)
    for index in range(1, RUNS + 1):
        r1 = NOMINAL_OHM * (1.0 + rng.uniform(-TOLERANCE, TOLERANCE))
        r2 = NOMINAL_OHM * (1.0 + rng.uniform(-TOLERANCE, TOLERANCE))
        rows.append(simulate(template, "monte_carlo", f"mc_{index:03d}", r1, r2))

    fields = ["kind", "case", "seed", "r1_ohm", "r2_ohm", "vout", "exit_code"]
    with (RESULTS / "raw_results.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)

    values = [float(row["vout"]) for row in rows if row["kind"] == "monte_carlo"]
    summary = {
        "ngspice": "42",
        "input_voltage_v": 1.8,
        "resistor_nominal_ohm": NOMINAL_OHM,
        "resistor_tolerance_fraction": TOLERANCE,
        "random_distribution": "independent uniform per resistor",
        "random_seed": SEED,
        "monte_carlo": {
            "count": len(values),
            "min_v": min(values),
            "max_v": max(values),
            "mean_v": statistics.mean(values),
            "sample_stddev_v": statistics.stdev(values),
        },
        "deterministic_v": {row["case"]: float(row["vout"]) for row in rows if row["kind"] == "deterministic"},
    }
    (RESULTS / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    mc = summary["monte_carlo"]
    print(f"MC_SUMMARY count={mc['count']} min_v={mc['min_v']:.12f} max_v={mc['max_v']:.12f} mean_v={mc['mean_v']:.12f} sample_stddev_v={mc['sample_stddev_v']:.12f}")
    for case, value in summary["deterministic_v"].items():
        print(f"CORNER_RESULT case={case} vout={value:.12f}")


if __name__ == "__main__":
    main()
