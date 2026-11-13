#!/usr/bin/env python3
"""M5 驱动：一条被 pre/post 钩子全程接管的工具调用会话。

四个观察点：
1. pre 权限钩子拒绝改测试文件，工具 handler 根本没执行（零副作用）；
2. pre 参数改写钩子把 list_files 的 max_entries 从 100 收敛到 10；
3. post 脱敏钩子把读回内容里带 SECRET 标记的行替换成掩码；
4. post 审计钩子把每次调用（含拒绝）落一行 JSONL。
产物：traces/m5-trace.jsonl（消息生命周期）与 traces/m5-audit.jsonl（审计流）。
只使用标准库。
"""

import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from mini_agent import ScriptedModel, Tracer, run_loop  # noqa: E402
from mini_agent.hooks import (  # noqa: E402
    ArgumentRewrite,
    AuditLog,
    HookedToolRegistry,
    PermissionPolicy,
    RedactSecrets,
)
from mini_agent.messages import system_msg, user_msg  # noqa: E402

CALC_BODY = (
    "# 计算器模块\n"
    "# SECRET token=abc123-do-not-leak\n"
    "def add(a, b):\n"
    "    return a + b\n"
)


def reset_workspace():
    workspace = ROOT / "workspace"
    if workspace.exists():
        shutil.rmtree(workspace)
    shutil.copytree(ROOT / "fixtures" / "workspace", workspace)
    (workspace / "calculator.py").write_text(CALC_BODY, encoding="utf-8")
    for i in range(15):
        (workspace / ("note%02d.txt" % i)).write_text("memo", encoding="utf-8")
    return workspace


def protect_tests(name, path):
    if path.endswith("test_calculator.py"):
        return "测试文件受保护：禁止 agent 直接修改测试"
    return ""


def build_registry(workspace, audit_path):
    return HookedToolRegistry(
        workspace,
        pre_hooks=[
            PermissionPolicy(path_rules=[protect_tests]),
            ArgumentRewrite(max_entries_cap=10),
        ],
        post_hooks=[
            RedactSecrets(),
            AuditLog(str(audit_path)),
        ],
    )


def scripted_replies():
    return [
        {"content": "先尝试直接改测试文件。", "tool_calls": [
            {"id": "m5_1", "name": "edit_file", "arguments": {
                "path": "test_calculator.py",
                "old_string": "def test_add():",
                "new_string": "def test_add_renamed():"}}]},
        {"content": "被策略拒绝，改读源码确认现状。", "tool_calls": [
            {"id": "m5_2", "name": "read_file",
             "arguments": {"path": "calculator.py"}}]},
        {"content": "列目录确认周边文件，故意要 100 条。", "tool_calls": [
            {"id": "m5_3", "name": "list_files",
             "arguments": {"path": ".", "max_entries": 100}}]},
        {"content": "改业务文件（允许的路径）。", "tool_calls": [
            {"id": "m5_4", "name": "edit_file", "arguments": {
                "path": "calculator.py",
                "old_string": "    return a + b",
                "new_string": "    return a + b + 0"}}]},
        {"content": "钩子链全程生效：拒绝零副作用、参数被收敛、密钥行已脱敏。"},
    ]


def main():
    workspace = reset_workspace()
    trace_dir = ROOT / "traces"
    trace_dir.mkdir(parents=True, exist_ok=True)
    trace_path = trace_dir / "m5-trace.jsonl"
    audit_path = trace_dir / "m5-audit.jsonl"
    if audit_path.exists():
        audit_path.unlink()

    messages = [
        system_msg("你是教学用 mini-agent，所有工具调用都会经过钩子链。"),
        user_msg("演示 hooks 机制：尝试改测试、读源码、列目录、再改业务文件。"),
    ]
    registry = build_registry(workspace, audit_path)
    model = ScriptedModel(scripted_replies(),
                          system_prompt=messages[0]["content"])

    def reporter(kind, *args):
        if kind == "assistant":
            reply = args[0]
            print("[assistant]", reply["content"])
            for call in reply.get("tool_calls", []):
                print("    -> tool_call:", call["name"], call["arguments"])
        else:
            call, result = args[0], args[1]
            first = result.content.splitlines()[0] if result.content else ""
            print("    <- tool_result:", call["name"],
                  "ok=" + str(result.ok), "|", first[:72])

    with Tracer(trace_path) as tracer:
        answer = run_loop(model, registry, messages, tracer,
                          max_steps=8, reporter=reporter)

    print("-" * 68)
    print("最终回复:", answer)
    print("被拒绝调用数:", len(registry.denied), registry.denied)
    test_body = (workspace / "test_calculator.py").read_text(encoding="utf-8")
    print("测试文件未被改动:", "test_add_renamed" not in test_body)
    audit = [json.loads(line) for line in
             audit_path.read_text(encoding="utf-8").splitlines()]
    print("审计记录 %d 条，工具序列: %s"
          % (len(audit), " -> ".join(row["tool"] for row in audit)))
    redacted = [m for m in messages
                if m.get("role") == "tool" and "******" in m.get("content", "")]
    print("脱敏生效的回流消息数:", len(redacted))
    print("trace:", trace_path.relative_to(ROOT))
    print("audit:", audit_path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
