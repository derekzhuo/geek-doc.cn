#!/usr/bin/env python3
import csv
import json
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"


def close(actual, expected, tolerance=1e-11):
    if not math.isclose(actual, expected, rel_tol=0.0, abs_tol=tolerance):
        raise AssertionError(f"{actual} != {expected}")


def main():
    with (RESULTS / "raw_results.csv").open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    summary = json.loads((RESULTS / "summary.json").read_text(encoding="utf-8"))
    mc = [row for row in rows if row["kind"] == "monte_carlo"]
    deterministic = [row for row in rows if row["kind"] == "deterministic"]
    assert len(mc) == 50, len(mc)
    assert len(deterministic) == 3, len(deterministic)
    assert [row["case"] for row in mc] == [f"mc_{index:03d}" for index in range(1, 51)]
    assert all(int(row["exit_code"]) == 0 for row in rows)

    rng = random.Random(20261126)
    for row in mc:
        expected_r1 = 10_000.0 * (1.0 + rng.uniform(-0.05, 0.05))
        expected_r2 = 10_000.0 * (1.0 + rng.uniform(-0.05, 0.05))
        close(float(row["r1_ohm"]), expected_r1)
        close(float(row["r2_ohm"]), expected_r2)
        assert int(row["seed"]) == 20261126

    values = [float(row["vout"]) for row in mc]
    mean = math.fsum(values) / len(values)
    stddev = math.sqrt(math.fsum((value - mean) ** 2 for value in values) / (len(values) - 1))
    reported = summary["monte_carlo"]
    assert reported["count"] == 50
    close(reported["min_v"], min(values))
    close(reported["max_v"], max(values))
    close(reported["mean_v"], mean)
    close(reported["sample_stddev_v"], stddev)
    print(f"VALIDATION count=50 random_sequence=match summary=match deterministic_cases={len(deterministic)} all_exit_codes=0")


if __name__ == "__main__":
    main()
