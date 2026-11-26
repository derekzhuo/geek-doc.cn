#!/usr/bin/env python3
"""Convert the scalar 0/1 signals in one VCD scope into a bounded SAIF file."""

import argparse
import datetime
from pathlib import Path


def parse_vcd(path, wanted_scope):
    with path.open(encoding="utf-8") as stream:
        lines = [line.strip() for line in stream if line.strip()]
    scopes = []
    ids = {}
    wanted_ids = {}
    in_definitions = True
    time = 0.0
    time_scale = 1.0
    changes = []
    for line in lines:
        tokens = line.split()
        if not tokens:
            continue
        if tokens[0] in {"1s", "1ms", "1us", "1ns", "1ps", "1fs"}:
            time_scale = {"1s": 1e9, "1ms": 1e6, "1us": 1e3,
                          "1ns": 1.0, "1ps": 1e-3, "1fs": 1e-6}[tokens[0]]
        elif tokens[0] == "$scope":
            scopes.append(tokens[2])
        elif tokens[0] == "$upscope":
            scopes.pop()
        elif tokens[0] == "$var":
            symbol, name = tokens[3], tokens[4]
            full_name = "/".join(scopes + [name])
            ids[symbol] = full_name
            if full_name.startswith(wanted_scope + "/"):
                short_name = full_name[len(wanted_scope) + 1:]
                if "/" not in short_name:
                    wanted_ids[symbol] = short_name
        elif tokens[0] == "$enddefinitions":
            in_definitions = False
        elif in_definitions:
            continue
        elif line.startswith("#"):
            time = int(line[1:]) * time_scale
        elif line[0] in "01" and len(line) >= 2:
            symbol = line[1:]
            if symbol in wanted_ids:
                changes.append((time, symbol, line[0]))
    return ids, wanted_ids, changes, time


def convert(args):
    _, wanted_ids, changes, end_time = parse_vcd(args.input, args.scope)
    if args.duration is not None:
        end_time = args.duration
    if not wanted_ids or end_time <= 0:
        raise SystemExit("no matching scalar signals or zero simulation duration")
    initial = {symbol: "0" for symbol in wanted_ids}
    for time, symbol, value in changes:
        if time == 0:
            initial[symbol] = value
    states = {symbol: [(0, initial[symbol])] for symbol in wanted_ids}
    for time, symbol, value in changes:
        if states[symbol][-1][1] != value:
            states[symbol].append((time, value))
    body = ["      (NET"]
    for symbol, short_name in sorted(wanted_ids.items(), key=lambda item: item[1]):
        durations = {"0": 0, "1": 0}
        toggles = 0
        events = states[symbol]
        for index, (start, value) in enumerate(events):
            stop = events[index + 1][0] if index + 1 < len(events) else end_time
            durations[value] += stop - start
            if index:
                toggles += 1
        assert durations["0"] + durations["1"] == end_time
        body.extend([
            f"        ({short_name}",
            f"          (T0 {durations['0']:g}) (T1 {durations['1']:g})",
            f"          (TC {toggles})",
            "        )",
        ])
        print(f"SAIF_NET scope={args.scope} net={short_name} T0={durations['0']:g} "
              f"T1={durations['1']:g} TC={toggles} duration={end_time:g}")
    if args.extra_unmapped:
        body.extend([
            f"        ({args.extra_unmapped}",
            f"          (T0 0) (T1 {end_time:g})",
            "          (TC 1)",
            "        )",
        ])
    body.append("      )")
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    parent, leaf = args.scope.rsplit("/", 1)
    text = "\n".join([
        "(SAIFILE",
        '  (SAIFVERSION "2.0")',
        '  (DIRECTION "backward")',
        "  (DESIGN )",
        f'  (DATE "{now}")',
        '  (VENDOR "Icarus Verilog VCD")',
        '  (PROGRAM_NAME "vcd_to_saif.py")',
        '  (VERSION "1")',
        "  (DIVIDER / )",
        "  (TIMESCALE 1 ns)",
        f"  (DURATION {end_time:g})",
        f"  (INSTANCE {parent}",
        f"    (INSTANCE {leaf}",
        *body,
        "    )",
        "  )",
        ")",
        "",
    ])
    args.output.write_text(text, encoding="utf-8")
    print(f"SAIF_RESULT nets={len(wanted_ids)} duration_ns={end_time} output={args.output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--scope", default="tb/dut")
    parser.add_argument("--duration", type=int)
    parser.add_argument("--extra-unmapped")
    convert(parser.parse_args())
