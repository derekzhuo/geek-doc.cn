#!/usr/bin/env python3
"""M4 驱动：主代理 fork 两个子代理并行改两个文件，并实测串并行耗时。

两部分产物：
- traces/m4-trace.jsonl      主代理完整 trace（含 subagent_fork/subagent_return
                              事件与聚合成一条 tool 消息的回传）
- traces/m4-benchmark.json   串行/并行各 reps 次的墙钟时间与中位数
- traces/m4-results.txt      多轮中位的人类可读摘要
终端同时打印编排过程、上下文隔离证据与计时对照表。只使用标准库。
"""

import json
import shutil
import statistics
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from mini_agent import (  # noqa: E402
    ForkingToolRegistry,
    MemoryTracer,
    ScriptedModel,
    SubagentJob,
    SubagentOrchestrator,
    SubagentRunner,
    Tracer,
    run_loop,
)
from mini_agent.messages import system_msg, user_msg  # noqa: E402


def reset_workspace(task):
    workspace = ROOT / "workspace"
    if workspace.exists():
        shutil.rmtree(workspace)
    shutil.copytree(ROOT / "fixtures" / "workspace", workspace)
    for name, content in task["files"].items():
        (workspace / name).write_text(content, encoding="utf-8")
    return workspace


def build_jobs(task):
    jobs = []
    for name, spec in task["subagents"].items():
        jobs.append(SubagentJob(
            name=name,
            task=spec["task"],
            script=spec["replies"],
            shared_inputs=dict(task["shared_inputs"]),
            max_steps=6,
            delay=task["delay"],
        ))
    return jobs


def _clip(text, limit=88):
    """按显示宽度裁剪长行（CJK 全角算 2 列），保证终端记录不折行。"""
    width = 0
    for idx, char in enumerate(text):
        width += 2 if ord(char) > 0x2E7F else 1
        if width > limit:
            return text[:idx] + "……"
    return text


def show_parent_loop(task, trace_path):
    """完整演示：主代理 loop 发出 fork_subagents 工具调用并聚合回传。"""
    workspace = reset_workspace(task)
    print("== 演示：主代理 fork 两个子代理并行改两个文件 ==")
    print("主任务:", _clip(task["task"]))
    print("共享只读输入:", _clip(", ".join(
        "%s=%s" % item for item in sorted(task["shared_inputs"].items())), 76))
    print("-" * 68)

    messages = [system_msg(task["system_prompt"]), user_msg(task["task"])]
    parent_history_snapshot = json.dumps(messages, ensure_ascii=False)

    with Tracer(trace_path) as tracer:
        registry = ForkingToolRegistry(
            workspace, tracer,
            {job.name: job for job in build_jobs(task)},
            parallel=True)
        model = ScriptedModel(task["parent_replies"],
                              system_prompt=task["system_prompt"])

        def reporter(kind, *args):
            if kind == "assistant":
                reply = args[0]
                print("[主代理 assistant]", reply["content"])
                for call in reply.get("tool_calls", []):
                    print("    -> tool_call:", call["name"], call["arguments"])
            else:
                call, result = args[0], args[1]
                first = result.content.splitlines()[0] if result.content else ""
                print("    <- tool_result:", call["name"],
                      "ok=" + str(result.ok), "|", first)

        answer = run_loop(model, registry, messages, tracer,
                          max_steps=6, reporter=reporter)

    results = registry.last_results
    print("-" * 68)
    print("主代理最终回复:", answer)
    print("主代理模型调用次数:", model.calls)
    print()
    print("-- 上下文隔离证据 --")
    print("父会话消息条数: %d（system+user+fork 调用+聚合 tool+最终回复）"
          % len(messages))
    tool_messages = [m for m in messages if m.get("role") == "tool"]
    print("父会话 tool 消息条数: %d（子代理中间消息不进父历史）"
          % len(tool_messages))
    for result in results:
        joined = json.dumps(result.messages, ensure_ascii=False)
        leak = parent_history_snapshot[:40] in joined
        print("子代理 %s：独立消息 %d 条、%d 轮、耗时 %.3fs、回传 ok=%s、"
              "父历史正文泄露=%s"
              % (result.name, len(result.messages), result.rounds,
                 result.elapsed, result.ok, leak))
    alpha_text = "".join(m.get("content", "")
                         for m in results[0].messages if m.get("role") == "tool")
    print("alpha 子代理的工具回流中出现 beta 字样:", "beta" in alpha_text)
    print("改动核对:")
    for name in task["files"]:
        body = (workspace / name).read_text(encoding="utf-8")
        head = body.splitlines()[1]
        print("  %s -> %s" % (name, head))
    print("trace:", trace_path.relative_to(ROOT))
    return results


def benchmark(task):
    """串行与并行各跑 reps 次（每次重置工作区），返回原始计时与中位数。"""
    jobs = build_jobs(task)
    reps = task["reps"]
    serial_runs, parallel_runs = [], []
    for _ in range(reps):
        reset_workspace(task)
        tracer = MemoryTracer()
        orchestrator = SubagentOrchestrator(
            SubagentRunner(ROOT / "workspace", tracer))
        _, serial_elapsed = orchestrator.run_serial(jobs)
        serial_runs.append(serial_elapsed)

        reset_workspace(task)
        tracer = MemoryTracer()
        orchestrator = SubagentOrchestrator(
            SubagentRunner(ROOT / "workspace", tracer))
        _, parallel_elapsed = orchestrator.run_parallel(jobs)
        parallel_runs.append(parallel_elapsed)

    serial_median = statistics.median(serial_runs)
    parallel_median = statistics.median(parallel_runs)
    return {
        "reps": reps,
        "delay_per_model_call_s": task["delay"],
        "subagent_rounds": len(jobs[0].script),
        "subagent_count": len(jobs),
        "serial_runs_s": [round(v, 4) for v in serial_runs],
        "parallel_runs_s": [round(v, 4) for v in parallel_runs],
        "serial_median_s": round(serial_median, 4),
        "parallel_median_s": round(parallel_median, 4),
        "speedup": round(serial_median / parallel_median, 2),
    }


def main():
    task = json.loads((ROOT / "scripts" / "m4_task.json").read_text(
        encoding="utf-8"))
    trace_dir = ROOT / "traces"
    trace_dir.mkdir(parents=True, exist_ok=True)

    show_parent_loop(task, trace_dir / "m4-trace.jsonl")
    print()

    data = benchmark(task)
    print("== 串行 vs 并行墙钟计时（time.perf_counter，重复 %d 次取中位） =="
          % data["reps"])
    print("每个子代理 %d 轮模型调用，每轮模拟推理延迟 %.2fs"
          % (data["subagent_rounds"], data["delay_per_model_call_s"]))
    print("%-6s %-12s %-12s %s" % ("轮次", "串行(s)", "并行(s)", "备注"))
    for idx in range(data["reps"]):
        note = ""
        print("%-6d %-12.4f %-12.4f %s"
              % (idx + 1, data["serial_runs_s"][idx],
                 data["parallel_runs_s"][idx], note))
    print("-" * 44)
    print("%-6s %-12.4f %-12.4f 加速比 %.2fx"
          % ("中位", data["serial_median_s"], data["parallel_median_s"],
             data["speedup"]))

    out_json = trace_dir / "m4-benchmark.json"
    out_json.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                        encoding="utf-8")
    out_txt = trace_dir / "m4-results.txt"
    out_txt.write_text(
        "mini-agent M4 子代理编排计时\n"
        "子代理 %d 个，每个 %d 轮模型调用，每轮 delay=%.2fs，重复 %d 次\n"
        "serial_median_s=%s\nparallel_median_s=%s\nspeedup=%s\n"
        "serial_runs_s=%s\nparallel_runs_s=%s\n"
        % (data["subagent_count"], data["subagent_rounds"],
           data["delay_per_model_call_s"], data["reps"],
           data["serial_median_s"], data["parallel_median_s"],
           data["speedup"], data["serial_runs_s"], data["parallel_runs_s"]),
        encoding="utf-8")
    print("数据文件:", out_json.relative_to(ROOT))
    print("中位摘要:", out_txt.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
