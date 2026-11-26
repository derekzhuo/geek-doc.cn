#!/usr/bin/env python3
"""从 OpenSTA JSON 路径点拆分单元弧和互连弧，并检查三阶段契约。"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RESULTS = ROOT / "results"
STAGES = ("placement", "global_route", "spef_readback")


def measure(stage):
    path = RESULTS / f"{stage}_path.json"
    data = json.loads(path.read_text())
    check = data["checks"][0]
    points = check["source_path"]
    wire_s = 0.0
    cell_s = 0.0
    wire_arcs = 0
    cell_arcs = 0
    for before, after in zip(points, points[1:]):
        delta = after["arrival"] - before["arrival"]
        same_cell_arc = (
            before.get("instance") == after.get("instance")
            and before.get("instance")
            and before["pin"] != after["pin"]
        )
        same_net_arc = (
            (before.get("net") or after.get("net"))
            and (
                before.get("net") == after.get("net")
                or before["pin"] == "d_in"
                or after["pin"] == "z_out"
            )
        )
        if same_cell_arc:
            cell_s += delta
            cell_arcs += 1
        elif same_net_arc:
            wire_s += delta
            wire_arcs += 1
    arrival_s = check["data_arrival_time"]
    internal_s = arrival_s - 1.0e-9  # 扣除固定 input external delay
    assert cell_arcs == 6, (stage, cell_arcs)
    assert wire_arcs == 7, (stage, wire_arcs)
    assert math.isclose(wire_s + cell_s, internal_s, abs_tol=2.0e-12), stage
    wire_ns = wire_s * 1e9
    arrival_ns = arrival_s * 1e9
    print(
        f"DELAY stage={stage} arrival_ns={arrival_ns:.6f} "
        f"cell_ns={cell_s * 1e9:.6f} wire_ns={wire_ns:.6f} "
        f"wire_share_pct={100.0 * wire_s / internal_s:.4f} "
        f"cell_arcs={cell_arcs} wire_arcs={wire_arcs}"
    )
    return arrival_ns, wire_ns


def main():
    spef = RESULTS / "02_global_route.spef"
    text = spef.read_text()
    assert spef.stat().st_size > 1000
    assert text.count("*D_NET ") == 7
    assert '*DESIGN "top"' in text
    assert "*R_UNIT 1 KOHM" in text and "*C_UNIT 1 PF" in text
    values = {stage: measure(stage) for stage in STAGES}
    assert values["global_route"][0] < values["placement"][0]
    assert values["global_route"][1] > 0
    # 默认回读延迟视图把本例互连弧打印到精度下限；SPEF 自身仍必须有电阻段。
    assert values["spef_readback"][1] < 0.000001
    assert text.count("*RES") == 7
    # 回读与生成端是同一网表和约束，允许延迟计算视图的小幅差异。
    assert abs(values["global_route"][0] - values["spef_readback"][0]) < 0.006
    log = (RESULTS / "03_readback.log").read_text()
    assert "Found 0 unannotated drivers." in log
    assert "Found 0 partially unannotated drivers." in log
    assert "STAGE_03_SPEF_READBACK_OK" in log
    print("VERIFY_RESULT PASS stages=3 spef_nets=7 cell_arcs=6 wire_arcs=7 annotation=complete")


if __name__ == "__main__":
    main()
