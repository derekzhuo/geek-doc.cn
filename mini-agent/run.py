#!/usr/bin/env python3
"""M1 入口：重置工作区 -> 载入任务脚本 -> 跑 agent loop -> 落 trace。

用法：
    python3 run.py                # 使用默认 M1 任务脚本
    python3 run.py --script scripts/m1_task.json
"""

import argparse
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

from mini_agent import ScriptedModel, ToolRegistry, Tracer, run_loop
from mini_agent.messages import system_msg, user_msg


def reset_workspace():
    workspace = ROOT / "workspace"
    if workspace.exists():
        shutil.rmtree(workspace)
    shutil.copytree(ROOT / "fixtures" / "workspace", workspace)
    return workspace


def main():
    parser = argparse.ArgumentParser(description="mini-agent M1 runner")
    parser.add_argument("--script", default="scripts/m1_task.json")
    parser.add_argument("--trace", default="traces/trace.jsonl")
    args = parser.parse_args()

    task = json.loads((ROOT / args.script).read_text(encoding="utf-8"))
    workspace = reset_workspace()
    trace_path = ROOT / args.trace
    trace_path.parent.mkdir(parents=True, exist_ok=True)

    print("== mini-agent %s ==" % task.get("milestone", "M1"))
    print("task:", task["task"])
    print("workspace: <workspace>  (fixtures/workspace 的干净副本)")
    print("-" * 60)

    model = ScriptedModel(task["replies"], system_prompt=task["system_prompt"])
    tools = ToolRegistry(workspace)
    messages = [system_msg(task["system_prompt"]), user_msg(task["task"])]

    def print_report(kind, *args):
        # 终端只展示相对路径与语义信息，不打印宿主机绝对路径。
        if kind == "assistant":
            reply = args[0]
            print("[assistant]", reply["content"])
            for call in reply.get("tool_calls", []):
                print("    -> tool_call:", call["name"], call["arguments"])
        else:
            call, result = args
            first_line = result.content.splitlines()[0] if result.content else ""
            print("    <- tool_result:", call["name"], "ok=" + str(result.ok), "|", first_line)

    with Tracer(trace_path) as tracer:
        answer = run_loop(model, tools, messages, tracer, reporter=print_report)

    print("-" * 60)
    print("final answer:", answer)
    print("model calls:", model.calls)
    print("trace:", args.trace, "(相对 mini-agent 目录)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
