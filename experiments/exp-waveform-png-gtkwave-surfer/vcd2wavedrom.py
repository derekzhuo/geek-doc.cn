#!/usr/bin/env python3
"""Minimal VCD -> WaveJSON (wavedrom) converter, stdlib only.

Extracts the requested signals, samples them at a fixed step, and emits
{ signal: [ {name, wave, data?}, ... ] }. Enough for small demo waves;
not a general-purpose converter.
"""
import json
import sys


def parse_vcd(path, wanted):
    id2name = {}
    samples = {w: [] for w in wanted}   # list of (time, value)
    t = 0
    with open(path, encoding="utf-8", errors="replace") as f:
        in_defs = True
        for line in f:
            line = line.strip()
            if in_defs:
                if line.startswith("$var"):
                    parts = line.split()
                    # $var wire 1 <id> <name> $end
                    id2name[parts[3]] = parts[4]
                elif line.startswith("$enddefinitions"):
                    in_defs = False
                continue
            if not line:
                continue
            if line[0] == "#":
                t = int(line[1:])
                continue
            if line[0] in "01xzXZ":
                val, sig_id = line[0], line[1:].strip()
            elif line[0] in "bB":
                parts = line.split()
                val, sig_id = parts[0][1:], parts[1]
            else:
                continue
            name = id2name.get(sig_id)
            if name in samples:
                samples[name].append((t, val))
    return samples


def to_wave(samples, step, cycles, width_map):
    sigs = []
    for name, tv in samples.items():
        values = []
        for c in range(cycles):
            tc = c * step
            v = None
            for t, vv in tv:
                if t <= tc:
                    v = vv
                else:
                    break
            values.append(v if v is not None else "x")
        w = width_map.get(name, 1)
        wave, data = [], []
        prev = None
        for v in values:
            if w == 1:
                wave.append({"0": "0", "1": "1"}.get(v, "x"))
            else:
                if v in ("x", "z"):
                    wave.append("x")
                    prev = None
                else:
                    n = int(v, 2)
                    wave.append("=")
                    if n != prev:
                        data.append(str(n))
                        prev = n
        entry = {"name": name, "wave": "".join(wave)}
        if data:
            entry["data"] = data
        sigs.append(entry)
    return {"signal": sigs}


def main():
    vcd, out = sys.argv[1], sys.argv[2]
    wanted = sys.argv[3].split(",")
    step = int(sys.argv[4]) if len(sys.argv) > 4 else 10000   # time units per cycle
    cycles = int(sys.argv[5]) if len(sys.argv) > 5 else 40
    width_map = {}
    for spec in sys.argv[6:] if len(sys.argv) > 6 else []:
        n, w = spec.split(":")
        width_map[n] = int(w)
    samples = parse_vcd(vcd, wanted)
    missing = [w for w in wanted if not samples.get(w)]
    if missing:
        print("ERROR: signals not found in VCD:", ",".join(missing))
        sys.exit(1)
    wave = to_wave(samples, step, cycles, width_map)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(wave, f, indent=2)
    print("wrote", out, "with signals:", ",".join(wanted))
    for s in wave["signal"]:
        print("  %-8s wave=%s data=%s" % (s["name"], s["wave"], s.get("data", "")))


if __name__ == "__main__":
    main()
