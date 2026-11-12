"""M4 子代理编排的 headless 测试。

覆盖：子上下文与父历史双向隔离、回传消息格式、并行快于串行、
失败子代理的结构化错误回传、未知任务报错、不同文件各自改对、
父级 trace 只收 fork/return 生命周期事件。
"""

import json
import shutil
import statistics
import sys
import tempfile
import unittest
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
    aggregate,
    run_loop,
)
from mini_agent.messages import system_msg, user_msg  # noqa: E402

ALPHA_BODY = "# alpha 模块\nVALUE = 1\n\n\ndef add(a, b):\n    return a + b\n"
BETA_BODY = "# beta 模块\nTIMEOUT = 5\n\n\ndef ping():\n    return 'pong'\n"

SHARED = {"编码规范": "只修改被指派的文件", "任务编号": "TEST-M4"}


def make_workspace():
    tmp = Path(tempfile.mkdtemp(prefix="mini-agent-m4-"))
    (tmp / "alpha_module.py").write_text(ALPHA_BODY, encoding="utf-8")
    (tmp / "beta_module.py").write_text(BETA_BODY, encoding="utf-8")
    return tmp


def alpha_job(delay=0.0):
    return SubagentJob(
        name="alpha",
        task="把 alpha_module.py 的 VALUE 从 1 调整为 42。",
        script=[
            {"content": "先读 alpha。", "tool_calls": [
                {"id": "t_a_1", "name": "read_file",
                 "arguments": {"path": "alpha_module.py"}}]},
            {"content": "精确替换。", "tool_calls": [
                {"id": "t_a_2", "name": "edit_file",
                 "arguments": {"path": "alpha_module.py",
                               "old_string": "VALUE = 1",
                               "new_string": "VALUE = 42"}}]},
            {"content": "alpha 子任务完成：VALUE 已调整为 42。"},
        ],
        shared_inputs=dict(SHARED), max_steps=6, delay=delay)


def beta_job(delay=0.0):
    return SubagentJob(
        name="beta",
        task="把 beta_module.py 的 TIMEOUT 从 5 调整为 30。",
        script=[
            {"content": "先读 beta。", "tool_calls": [
                {"id": "t_b_1", "name": "read_file",
                 "arguments": {"path": "beta_module.py"}}]},
            {"content": "精确替换。", "tool_calls": [
                {"id": "t_b_2", "name": "edit_file",
                 "arguments": {"path": "beta_module.py",
                               "old_string": "TIMEOUT = 5",
                               "new_string": "TIMEOUT = 30"}}]},
            {"content": "beta 子任务完成：TIMEOUT 已调整为 30。"},
        ],
        shared_inputs=dict(SHARED), max_steps=6, delay=delay)


def parent_replies():
    return [
        {"content": "两个模块独立，fork 两个子代理并行处理。", "tool_calls": [
            {"id": "fork_1", "name": "fork_subagents",
             "arguments": {"jobs": ["alpha", "beta"]}}]},
        {"content": "两个子代理均已回传，主任务汇总完成。"},
    ]


class IsolationTest(unittest.TestCase):
    def setUp(self):
        self.workspace = make_workspace()
        self.addCleanup(shutil.rmtree, self.workspace)

    def test_sub_context_does_not_inherit_parent_history(self):
        parent_messages = [
            system_msg("主代理系统提示"),
            user_msg("父会话私有标记-PARENT-SECRET-9F3A，子代理绝不可见"),
        ]
        runner = SubagentRunner(self.workspace, MemoryTracer())
        result = runner.run(alpha_job())
        self.assertTrue(result.ok)
        self.assertEqual([m["role"] for m in result.messages[:2]],
                         ["system", "user"])
        joined = json.dumps(result.messages, ensure_ascii=False)
        self.assertNotIn("PARENT-SECRET-9F3A", joined)
        # 共享只读输入通过任务消息显式下发，而不是靠继承父历史得到。
        self.assertIn("TEST-M4", joined)
        # 父历史对象本身没有被追加任何东西。
        self.assertEqual(len(parent_messages), 2)

    def test_parent_only_sees_aggregated_tool_message(self):
        trace_path = self.workspace / "parent.jsonl"
        with Tracer(trace_path) as tracer:
            registry = ForkingToolRegistry(
                self.workspace, tracer,
                {"alpha": alpha_job(), "beta": beta_job()},
                parallel=True)
            messages = [system_msg("主代理系统提示"),
                        user_msg("横跨两个模块的改动请求")]
            model = ScriptedModel(parent_replies(),
                                  system_prompt="主代理系统提示")
            answer = run_loop(model, registry, messages, tracer, max_steps=6)

        tool_messages = [m for m in messages if m.get("role") == "tool"]
        self.assertEqual(len(tool_messages), 1)
        self.assertEqual(tool_messages[0]["tool_call_id"], "fork_1")
        self.assertIn("alpha", tool_messages[0]["content"])
        self.assertIn("beta", tool_messages[0]["content"])
        # 子代理内部的 read/edit 工具配对不得出现在父历史里。
        parent_joined = json.dumps(messages, ensure_ascii=False)
        self.assertNotIn("t_a_1", parent_joined)
        self.assertNotIn("t_b_2", parent_joined)
        self.assertIn("汇总完成", answer)

    def test_distinct_files_edited_without_cross_touch(self):
        tracer = MemoryTracer()
        orchestrator = SubagentOrchestrator(
            SubagentRunner(self.workspace, tracer))
        results, _ = orchestrator.run_parallel([alpha_job(), beta_job()])
        self.assertTrue(all(r.ok for r in results))
        alpha_now = (self.workspace / "alpha_module.py").read_text(
            encoding="utf-8")
        beta_now = (self.workspace / "beta_module.py").read_text(
            encoding="utf-8")
        self.assertIn("VALUE = 42", alpha_now)
        self.assertNotIn("VALUE = 42", beta_now)
        self.assertIn("TIMEOUT = 30", beta_now)
        alpha_trace = json.dumps(results[0].messages, ensure_ascii=False)
        beta_trace = json.dumps(results[1].messages, ensure_ascii=False)
        self.assertNotIn("beta", alpha_trace)
        self.assertNotIn("alpha_module", beta_trace)


class ResultAndTimingTest(unittest.TestCase):
    def setUp(self):
        self.workspace = make_workspace()
        self.addCleanup(shutil.rmtree, self.workspace)

    def test_result_dict_format_and_rounds(self):
        runner = SubagentRunner(self.workspace, MemoryTracer())
        result = runner.run(alpha_job())
        data = result.as_dict()
        for key in ("name", "ok", "final_reply", "rounds",
                    "elapsed", "message_count"):
            self.assertIn(key, data)
        self.assertEqual(data["name"], "alpha")
        self.assertTrue(data["ok"])
        self.assertEqual(data["rounds"], 3)
        self.assertGreaterEqual(data["elapsed"], 0.0)
        kinds = [r["event"] for r in result.records if r["type"] == "event"]
        self.assertIn("session_start", kinds)
        self.assertIn("session_end", kinds)

    def test_parallel_median_faster_than_serial(self):
        delay = 0.05
        serial_runs, parallel_runs, solo_runs = [], [], []
        for _ in range(3):
            tracer = MemoryTracer()
            runner = SubagentRunner(self.workspace, tracer)
            orch = SubagentOrchestrator(runner)
            _, serial = orch.run_serial([alpha_job(delay), beta_job(delay)])
            serial_runs.append(serial)

            tracer = MemoryTracer()
            runner = SubagentRunner(self.workspace, tracer)
            orch = SubagentOrchestrator(runner)
            _, parallel = orch.run_parallel(
                [alpha_job(delay), beta_job(delay)])
            parallel_runs.append(parallel)

            tracer = MemoryTracer()
            runner = SubagentRunner(self.workspace, tracer)
            solo = runner.run(alpha_job(delay)).elapsed
            solo_runs.append(solo)

        serial_median = statistics.median(serial_runs)
        parallel_median = statistics.median(parallel_runs)
        # 两个等长子任务：并行墙钟应显著短于串行，且不会短于单个子任务。
        self.assertLess(parallel_median, serial_median * 0.8)
        self.assertGreaterEqual(parallel_median,
                                statistics.median(solo_runs) * 0.8)

    def test_failure_returns_structured_error_and_never_raises(self):
        broken = SubagentJob(
            name="broken", task="一个注定失败的任务",
            script=[], shared_inputs={}, max_steps=4)
        tracer = MemoryTracer()
        orchestrator = SubagentOrchestrator(
            SubagentRunner(self.workspace, tracer))
        results, elapsed = orchestrator.run_parallel(
            [broken, alpha_job()])
        failed, good = results[0], results[1]
        self.assertFalse(failed.ok)
        self.assertEqual(failed.error["code"], "subagent_failed")
        self.assertEqual(failed.error["subagent"], "broken")
        self.assertTrue(good.ok)
        text = aggregate(results, "parallel", elapsed)
        self.assertIn("失败", text)
        self.assertIn("alpha", text)

        # 经过 fork 工具回流时，失败同样表现为结构化 ToolResult。
        with Tracer(self.workspace / "t.jsonl") as parent_tracer:
            registry = ForkingToolRegistry(
                self.workspace, parent_tracer,
                {"broken": broken, "alpha": alpha_job()}, parallel=True)
            tool_result = registry.dispatch(
                "fork_subagents", {"jobs": ["broken", "alpha"]})
        self.assertFalse(tool_result.ok)
        self.assertEqual(tool_result.error["code"], "subagent_failed")

    def test_unknown_subagent_job_is_structured_error(self):
        with Tracer(self.workspace / "t2.jsonl") as tracer:
            registry = ForkingToolRegistry(
                self.workspace, tracer,
                {"alpha": alpha_job()}, parallel=True)
            result = registry.dispatch(
                "fork_subagents", {"jobs": ["ghost"]})
        self.assertFalse(result.ok)
        self.assertEqual(result.error["code"], "unknown_subagent")

    def test_parent_tracer_only_gets_lifecycle_events(self):
        trace_path = self.workspace / "parent-events.jsonl"
        with Tracer(trace_path) as tracer:
            runner = SubagentRunner(self.workspace, tracer)
            runner.run(alpha_job())
        records = [json.loads(line) for line in
                   trace_path.read_text(encoding="utf-8").splitlines()]
        events = [r for r in records if r["type"] == "event"]
        kinds = [r["event"] for r in events]
        self.assertEqual(kinds.count("subagent_fork"), 1)
        self.assertEqual(kinds.count("subagent_return"), 1)
        returned = next(r for r in events if r["event"] == "subagent_return")
        self.assertTrue(returned["payload"]["ok"])
        self.assertEqual(returned["payload"]["name"], "alpha")
        # 子代理的中间消息只留在它自己的内存 trace 里，不进父级 JSONL。
        self.assertFalse(any(r["type"] == "message" for r in records))


if __name__ == "__main__":
    unittest.main()
