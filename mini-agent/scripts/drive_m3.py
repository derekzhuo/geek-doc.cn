#!/usr/bin/env python3
"""M3 驱动：灌一条 13 轮工具调用的长会话，对照「不压缩基线」与「压缩管道」。

产物：
- traces/m3-trace.jsonl   压缩会话的完整 JSONL trace（含 context_compression 事件）
- traces/m3-tokens.json   逐轮 token 对照序列，供画曲线图使用
终端同时打印逐轮对照表。只使用标准库，可重复运行、逐字节复现。
"""

import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from mini_agent import (  # noqa: E402
    AgingCompressor,
    CompressionPipeline,
    ContextWindow,
    ScriptedModel,
    SummaryCompressor,
    ToolRegistry,
    Tracer,
    estimate_tokens,
    run_loop,
)
from mini_agent.messages import system_msg, user_msg  # noqa: E402

NOTE_LINES = 200


def reset_workspace():
    workspace = ROOT / "workspace"
    if workspace.exists():
        shutil.rmtree(workspace)
    shutil.copytree(ROOT / "fixtures" / "workspace", workspace)
    lines = []
    for i in range(1, NOTE_LINES + 1):
        lines.append(
            "NOTE %04d: synthetic long note line for context compression "
            "experiment round %03d." % (i, i))
    (workspace / "long_notes.txt").write_text("\n".join(lines) + "\n",
                                               encoding="utf-8")
    return workspace


def build_messages(task):
    return [system_msg(task["system_prompt"]), user_msg(task["task"])]


def run_session(task, workspace, trace_path, context_window):
    model = ScriptedModel(task["replies"], system_prompt=task["system_prompt"])
    tools = ToolRegistry(workspace)
    messages = build_messages(task)
    series = []

    def collect(step, tokens, reports):
        series.append({
            "step": step,
            "tokens": tokens,
            "messages": len(messages),
            "events": [report.strategy for report in reports],
        })

    context_window.observers.append(collect)
    with Tracer(trace_path) as tracer:
        answer = run_loop(model, tools, messages, tracer,
                          max_steps=len(task["replies"]) + 2,
                          context_window=context_window)
    return model, messages, answer, series


def main():
    task = json.loads((ROOT / "scripts" / "m3_task.json").read_text(encoding="utf-8"))
    threshold = task["threshold"]
    trace_dir = ROOT / "traces"
    trace_dir.mkdir(parents=True, exist_ok=True)

    # 基线会话：阈值放到无穷大，管道为空，只观测不压缩。
    baseline_window = ContextWindow(10 ** 9, CompressionPipeline([]))
    _, _, _, baseline_series = run_session(
        task, reset_workspace(), trace_dir / "m3-baseline-trace.jsonl",
        baseline_window)

    # 压缩会话：先老化旧工具结果，仍超阈值再滚动摘要。
    model = ScriptedModel(task["replies"], system_prompt=task["system_prompt"])
    summarizer = model
    pipeline = CompressionPipeline([
        AgingCompressor(threshold),
        SummaryCompressor(threshold, summarizer, keep_recent=4),
    ])
    compressed_window = ContextWindow(threshold, pipeline)
    model_c, messages_c, answer, compressed_series = run_session(
        task, reset_workspace(), trace_dir / "m3-trace.jsonl",
        compressed_window)

    steps = []
    for base, comp in zip(baseline_series, compressed_series):
        steps.append({
            "step": base["step"],
            "baseline_tokens": base["tokens"],
            "compressed_tokens": comp["tokens"],
            "baseline_messages": base["messages"],
            "compressed_messages": comp["messages"],
            "events": comp["events"],
        })
    payload = {
        "threshold": threshold,
        "estimator": "cjk_char=1 token, other chars/4, 4 per message, 8+name per tool_call",
        "note_lines": NOTE_LINES,
        "steps": steps,
        "final_messages": len(messages_c),
        "final_answer": answer,
        "model_calls": model_c.calls,
    }
    out = trace_dir / "m3-tokens.json"
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2),
                   encoding="utf-8")

    print("== mini-agent M3 长会话压缩对照（阈值 %d token） ==" % threshold)
    print("%-4s %-12s %-12s %-10s %s" %
          ("轮次", "基线token", "压缩后token", "节省", "本轮事件"))
    for item in steps:
        saved = item["baseline_tokens"] - item["compressed_tokens"]
        events = ",".join(item["events"]) or "-"
        print("%-4d %-12d %-12d %-10d %s" %
              (item["step"], item["baseline_tokens"],
               item["compressed_tokens"], saved, events))
    print("-" * 64)
    print("模型调用次数:", model_c.calls)
    print("压缩会话最终消息条数:", len(messages_c))
    print("最终 token:", estimate_tokens(messages_c))
    print("数据文件:", out.relative_to(ROOT))
    print("trace:", (trace_dir / "m3-trace.jsonl").relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
