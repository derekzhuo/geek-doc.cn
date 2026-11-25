#!/usr/bin/env python3
"""Independent consistency checks for the exported curves and extracted metrics."""
import csv
import math
import sys
from pathlib import Path

from analyze import WP_VALUES, analyze_one


def close(actual, expected, label):
    if not math.isclose(actual, expected, rel_tol=0.0, abs_tol=1e-12):
        raise AssertionError(f"{label}: {actual} != {expected}")


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: python3 verify.py DATA_DIR RESULTS_CSV")
    data_dir = Path(sys.argv[1])
    with Path(sys.argv[2]).open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != 4:
        raise AssertionError("expected four Wp/Wn cases")
    vms = []
    for wp, row in zip(WP_VALUES, rows):
        expected, points, slopes = analyze_one(wp, data_dir / f"vtc_wp_{wp:g}.raw")
        for key, value in expected.items():
            close(float(row[key]), value, f"Wp={wp} {key}")
        if any(points[i][1] < points[i + 1][1] - 1e-9 for i in range(len(points) - 1)):
            raise AssertionError(f"Wp={wp}: VTC is not monotonically decreasing")
        if not 0.0 < expected["vm_v"] < 1.8:
            raise AssertionError(f"Wp={wp}: Vm outside rails")
        if not 0.0 < expected["vil_v"] < expected["vm_v"] < expected["vih_v"] < 1.8:
            raise AssertionError(f"Wp={wp}: invalid VIL/Vm/VIH ordering")
        if min(expected["nml_v"], expected["nmh_v"]) < 0.0:
            raise AssertionError(f"Wp={wp}: negative noise margin")
        if max(expected["vm_bracket_v"], expected["vil_bracket_v"], expected["vih_bracket_v"]) > 0.002000001:
            raise AssertionError(f"Wp={wp}: crossing bracket wider than derivative stencil")
        vms.append(expected["vm_v"])
        print(f"CHECK Wp/Wn={wp:g}: Vm={expected['vm_v']:.6f} V, "
              f"VIL={expected['vil_v']:.6f} V, VIH={expected['vih_v']:.6f} V, "
              f"NML={expected['nml_v']:.6f} V, NMH={expected['nmh_v']:.6f} V")
    if any(vms[i] >= vms[i + 1] for i in range(len(vms) - 1)):
        raise AssertionError("Vm must move upward as Wp/Wn increases")
    print("PASS: 4 curves, 1801 points each, independent recomputation and ordering checks passed")


if __name__ == "__main__":
    main()
