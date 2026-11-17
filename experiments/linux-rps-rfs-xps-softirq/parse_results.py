#!/usr/bin/env python3
"""把 LP16 四组（+高压档）原始日志汇总成 results.csv，数字全部来自 raw/ 实测。"""
import csv
import glob
import os
import re

BASE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(BASE, "raw")


def section(txt, marker):
    m = re.search(re.escape(marker) + r"(.*?)(?:\n--- |\Z)", txt, re.S)
    return m.group(1) if m else ""


def softnet(txt, marker):
    rows = []
    for line in section(txt, marker).strip().splitlines():
        p = line.split()
        if len(p) == 13:
            rows.append([int(x, 16) for x in p])
    return rows


def irq(txt, marker):
    out = {}
    for line in section(txt, marker).strip().splitlines():
        p = line.split()
        if len(p) >= 4 and p[0].rstrip(":").isdigit():
            out[p[-1]] = (int(p[1]), int(p[2]))
    return out


def parse_one(path):
    tag = os.path.basename(path)[7:-4]
    txt = open(path).read()
    avgs = {}
    for line in section(txt, "--- mpstat average ---").splitlines():
        p = line.split()
        if p and p[0] == "Average:" and p[1] in ("all", "0", "1"):
            avgs[p[1]] = {"usr": float(p[2]), "sys": float(p[4]), "soft": float(p[7]), "idle": float(p[11])}
    sb, sa = softnet(txt, "--- softnet before ---"), softnet(txt, "--- softnet after ---")
    ib, ia = irq(txt, "--- irq before ---"), irq(txt, "--- irq after ---")
    row = {"tag": tag}
    for cpu in ("all", "0", "1"):
        if cpu in avgs:
            row[f"soft_{cpu}"] = avgs[cpu]["soft"]
            row[f"idle_{cpu}"] = avgs[cpu]["idle"]
    for i in range(len(sa)):
        row[f"proc_cpu{i}"] = sa[i][0] - sb[i][0]
        row[f"rps_in_cpu{i}"] = sa[i][9] - sb[i][9]
        row[f"drop_cpu{i}"] = sa[i][1] - sb[i][1]
    for k in ia:
        d0 = ia[k][0] - ib.get(k, (0, 0))[0]
        d1 = ia[k][1] - ib.get(k, (0, 0))[1]
        if d0 or d1:
            row[f"irq_{k.replace('.', '_')}_cpu0"] = d0
            row[f"irq_{k.replace('.', '_')}_cpu1"] = d1
    wrk = path.replace("result.", "wrk.").replace(".log", ".log")
    if os.path.exists(wrk):
        w = open(wrk).read()
        m = re.search(r"Requests/sec:\s+([\d.]+)", w)
        row["rps"] = float(m.group(1)) if m else ""
        m = re.search(r"(\d+) requests in", w)
        row["requests"] = int(m.group(1)) if m else ""
        m = re.search(r"Socket errors: connect (\d+), read (\d+), write (\d+), timeout (\d+)", w)
        row["socket_errors"] = sum(map(int, m.groups())) if m else 0
        m = re.search(r"Non-2xx or 3xx responses: (\d+)", w)
        row["non2xx"] = int(m.group(1)) if m else 0
        m = re.search(r"99%\s+([\d.]+)(\w+)", w)
        if m:
            v = float(m.group(1))
            row["p99_ms"] = v / 1000 if m.group(2) == "us" else v
    return row


def main():
    rows = [parse_one(f) for f in sorted(glob.glob(os.path.join(RAW, "result.g*-ka.log")) +
                                         glob.glob(os.path.join(RAW, "result.g*-close.log")))]
    keys = sorted({k for r in rows for k in r})
    front = ["tag", "rps", "requests", "p99_ms", "socket_errors", "non2xx",
             "soft_all", "soft_0", "soft_1", "idle_0", "idle_1",
             "proc_cpu0", "proc_cpu1", "rps_in_cpu0", "rps_in_cpu1", "drop_cpu0", "drop_cpu1"]
    keys = [k for k in front if k in keys] + [k for k in keys if k not in front]
    out = os.path.join(BASE, "results.csv")
    with open(out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=keys)
        w.writeheader()
        for r in rows:
            w.writerow(r)
    print("saved", out, len(rows), "rows")
    for r in rows:
        print(r["tag"], "rps=", r.get("rps"), "soft0=", r.get("soft_0"), "soft1=", r.get("soft_1"),
              "proc=", r.get("proc_cpu0"), r.get("proc_cpu1"), "rps_in=", r.get("rps_in_cpu0"), r.get("rps_in_cpu1"))


if __name__ == "__main__":
    main()
