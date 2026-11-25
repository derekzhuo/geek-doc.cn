#!/usr/bin/env python3
"""Extract VTC metrics from ngspice wrdata using only the Python standard library."""
import csv
import json
import math
import sys
from pathlib import Path

WP_VALUES = (0.5, 1.0, 2.0, 4.0)
VDD = 1.8
STEP = 0.001


def read_wrdata(path):
    points = []
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            fields = line.split()
            if not fields:
                continue
            if len(fields) != 4:
                raise ValueError(f"{path}: expected four numeric columns")
            scale1, vin, scale2, vout = map(float, fields)
            if not math.isclose(scale1, scale2, abs_tol=1e-12):
                raise ValueError(f"{path}: inconsistent sweep scales")
            points.append((vin, vout))
    if len(points) != 1801:
        raise ValueError(f"{path}: expected 1801 points, got {len(points)}")
    if any(points[i][0] >= points[i + 1][0] for i in range(len(points) - 1)):
        raise ValueError(f"{path}: input sweep is not strictly increasing")
    return points


def crossing(points, function, start=0, stop=None):
    """Linearly interpolate the first root in [start, stop)."""
    stop = len(points) if stop is None else stop
    previous_x = points[start][0]
    previous_y = function(points[start])
    if abs(previous_y) < 1e-15:
        return previous_x, previous_x, previous_x
    for i in range(start + 1, stop):
        x = points[i][0]
        y = function(points[i])
        if abs(y) < 1e-15:
            return x, x, x
        if previous_y * y < 0:
            fraction = -previous_y / (y - previous_y)
            estimate = previous_x + fraction * (x - previous_x)
            return estimate, previous_x, x
        previous_x, previous_y = x, y
    raise ValueError("no sign-changing crossing in requested interval")


def derivative(points):
    slopes = []
    for i in range(len(points)):
        if i == 0:
            lo, hi = 0, 1
        elif i == len(points) - 1:
            lo, hi = i - 1, i
        else:
            lo, hi = i - 1, i + 1
        dv = points[hi][1] - points[lo][1]
        dx = points[hi][0] - points[lo][0]
        slopes.append(dv / dx)
    return slopes


def analyze_one(wp, path):
    points = read_wrdata(path)
    slopes = derivative(points)
    vm, vm_lo, vm_hi = crossing(points, lambda p: p[1] - p[0])
    vil, vil_lo, vil_hi = crossing(points, lambda p: slopes[points.index(p)] + 1.0,
                                   0, points.index(min(points, key=lambda p: abs(p[1] - p[0]))) + 1)
    vm_index = min(range(len(points)), key=lambda i: abs(points[i][1] - points[i][0]))
    vih, vih_lo, vih_hi = crossing(points, lambda p: slopes[points.index(p)] + 1.0,
                                   vm_index, len(points))
    voh = points[0][1]
    vol = points[-1][1]
    result = {
        "wp_um": wp,
        "wn_um": 1.0,
        "wp_wn": wp,
        "vm_v": vm,
        "vil_v": vil,
        "vih_v": vih,
        "vol_v": vol,
        "voh_v": voh,
        "nml_v": vil - vol,
        "nmh_v": voh - vih,
        "vm_bracket_v": vm_hi - vm_lo,
        "vil_bracket_v": vil_hi - vil_lo,
        "vih_bracket_v": vih_hi - vih_lo,
        "vm_slope": slopes[vm_index],
        "min_slope": min(slopes),
    }
    return result, points, slopes


def main():
    if len(sys.argv) != 4:
        raise SystemExit("usage: python3 analyze.py DATA_DIR RESULTS_CSV SUMMARY_JSON")
    data_dir = Path(sys.argv[1])
    rows = []
    for wp in WP_VALUES:
        label = f"{wp:g}"
        row, _, _ = analyze_one(wp, data_dir / f"vtc_wp_{label}.raw")
        rows.append(row)
    fields = list(rows[0])
    with Path(sys.argv[2]).open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    payload = {
        "model": "ngspice LEVEL=1 teaching MOS",
        "vdd_v": VDD,
        "temperature_c": 27,
        "length_um": 0.18,
        "load_f": 1e-15,
        "sweep_step_v": STEP,
        "points_per_curve": 1801,
        "derivative": "three-point centered difference; one-sided at endpoints",
        "interpolation": "linear interpolation between adjacent samples",
        "quantization_bound_v": STEP / 2,
        "results": rows,
    }
    Path(sys.argv[3]).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
