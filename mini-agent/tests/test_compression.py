"""M3 上下文压缩的 headless 测试。

覆盖：字符级 token 口径、阈值触发、保护消息不可压、老化幂等、
摘要只替换闭合配对组、压缩后 loop 仍可收敛、trace 事件字段与硬失败。
"""

import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from mini_agent import (  # noqa: E402
    AgingCompressor,
    CompressionPipeline,
    ContextOverflowError,
    ContextWindow,
    ScriptedModel,
    SummaryCompressor,
    ToolRegistry,
    Tracer,
    estimate_tokens,
    run_loop,
)
from mini_agent.messages import assistant_msg, system_msg, tool_msg, user_msg  # noqa: E402
from mini_agent.model import ScriptedModel as Model  # noqa: E402


def make_tool_chain(call_id, content, name="read_file"):
    assistant = assistant_msg("请求 %s" % call_id, tool_calls=[
        {"id": call_id, "name": name, "arguments": {}}])
    tool = tool_msg(call_id, content)
    return assistant, tool


class EstimatorTest(unittest.TestCase):
    def test_cjk_and_ascii_weighting(self):
        cjk_only = [user_msg("一二三四")]
        ascii_only = [user_msg("a" * 16)]
        self.assertEqual(estimate_tokens(cjk_only), 4 + 4)
        self.assertEqual(estimate_tokens(ascii_only), 4 + 4)

    def test_estimator_is_deterministic(self):
        messages = [system_msg("sys"), user_msg("任务" * 20)]
        self.assertEqual(estimate_tokens(messages), estimate_tokens(messages))

    def test_tool_call_adds_structural_cost(self):
        plain = [assistant_msg("文本")]
        with_call = [assistant_msg("文本", tool_calls=[
            {"id": "c1", "name": "read_file", "arguments": {}}])]
        self.assertGreater(estimate_tokens(with_call), estimate_tokens(plain))


class AgingTest(unittest.TestCase):
    def _trace(self):
        tmp = Path(tempfile.mkdtemp(prefix="mini-agent-m3-"))
        return Tracer(tmp / "trace.jsonl"), tmp

    def test_below_threshold_is_noop(self):
        messages = [system_msg("s"), user_msg("u")]
        compressor = AgingCompressor(token_threshold=10000)
        self.assertIsNone(compressor.maybe_compress(messages))
        self.assertEqual(len(messages), 2)

    def test_aging_keeps_id_role_and_pairing(self):
        big = "x" * 2000
        messages = [system_msg("s"), user_msg("u")]
        for i in range(4):
            assistant, tool = make_tool_chain("c%d" % i, big)
            messages.extend([assistant, tool])
        tracer, tmp = self._trace()
        try:
            compressor = AgingCompressor(token_threshold=200)
            report = compressor.maybe_compress(messages, tracer=tracer, step=1)
        finally:
            tracer.close()
        self.assertIsNotNone(report)
        self.assertEqual(report.strategy, "tool_result_aging")
        self.assertEqual(report.before_messages, report.after_messages)
        self.assertLess(report.after_tokens, report.before_tokens)
        # 条数、角色与 tool_call_id 全部保留
        self.assertEqual(len(messages), 10)
        self.assertTrue(all(msg["role"] != "system" or msg["content"] == "s"
                            for msg in messages))
        aged = [msg for msg in messages
                if msg["role"] == "tool"
                and msg["content"].startswith("【工具结果已老化】")]
        self.assertTrue(aged)
        self.assertTrue(all(msg.get("tool_call_id", "").startswith("c")
                            for msg in messages if msg["role"] == "tool"))
        shutil.rmtree(tmp, ignore_errors=True)

    def test_aging_is_idempotent(self):
        messages = [system_msg("s"), user_msg("u")]
        for i in range(3):
            messages.extend(make_tool_chain("c%d" % i, "y" * 1500))
        compressor = AgingCompressor(token_threshold=200,
                                     min_content_len=240)
        first = compressor.maybe_compress(messages)
        second = compressor.maybe_compress(messages)
        self.assertIsNotNone(first)
        self.assertIsNone(second)

    def test_system_message_is_never_touched(self):
        messages = [system_msg("s"), user_msg("u")]
        messages.extend(make_tool_chain("c1", "z" * 1500))
        compressor = AgingCompressor(token_threshold=10)
        report = compressor.maybe_compress(messages)
        self.assertIsNotNone(report)
        # system/user/assistant 原样保留，只有 tool 内容被截断
        self.assertEqual(messages[0]["content"], "s")
        self.assertEqual(messages[1]["content"], "u")
        self.assertEqual(messages[3]["tool_call_id"], "c1")
        self.assertLess(len(messages[3]["content"]), 1500)


class SummaryTest(unittest.TestCase):
    def test_summary_replaces_only_closed_groups(self):
        messages = [system_msg("s"), user_msg("u")]
        a1, t1 = make_tool_chain("c1", "p" * 800)
        a2, t2 = make_tool_chain("c2", "q" * 800)
        tail = assistant_msg("收尾文本，不带工具调用")
        messages.extend([a1, t1, a2, t2, tail])
        model = Model([])
        compressor = SummaryCompressor(100, model, keep_recent=2)
        report = compressor.maybe_compress(messages)
        self.assertIsNotNone(report)
        # 保护头两条与尾部两条，中间 c1 配对组被一条摘要替换
        self.assertEqual(messages[0]["role"], "system")
        self.assertEqual(messages[1]["role"], "user")
        self.assertEqual(messages[-1]["content"], "收尾文本，不带工具调用")
        self.assertIn("【早期会话摘要】", messages[2]["content"])
        # 不存在失去配对的 tool 消息
        call_ids = {call["id"] for msg in messages
                    for call in msg.get("tool_calls", [])}
        tool_ids = {msg.get("tool_call_id") for msg in messages
                    if msg["role"] == "tool"}
        self.assertTrue(tool_ids.issubset(call_ids))
        self.assertLess(report.after_tokens, report.before_tokens)

    def test_summary_uses_model_adapter_text(self):
        messages = [system_msg("s"), user_msg("u")]
        messages.extend(make_tool_chain("c1", "r" * 800))
        messages.extend(make_tool_chain("c2", "r" * 800))
        model = Model([])
        compressor = SummaryCompressor(100, model, keep_recent=0)
        compressor.maybe_compress(messages)
        summary = messages[2]["content"]
        self.assertIn("read_file", summary)
        self.assertIn("共压缩 4 条", summary)


class ContextWindowTest(unittest.TestCase):
    def test_hard_failure_when_nothing_compressible(self):
        messages = [system_msg("s"), user_msg("u" * 4000)]
        pipeline = CompressionPipeline([
            AgingCompressor(100), SummaryCompressor(100, Model([]))])
        window = ContextWindow(100, pipeline)
        tracer_dir = Path(tempfile.mkdtemp(prefix="mini-agent-m3-"))
        try:
            with Tracer(tracer_dir / "t.jsonl") as tracer:
                with self.assertRaises(ContextOverflowError):
                    window.before_model_call(messages, tracer, 0)
        finally:
            shutil.rmtree(tracer_dir, ignore_errors=True)


class FullLoopM3Test(unittest.TestCase):
    def setUp(self):
        self.task = json.loads(
            (ROOT / "scripts" / "m3_task.json").read_text(encoding="utf-8"))
        self.workspace = Path(tempfile.mkdtemp(prefix="mini-agent-m3-ws-"))
        shutil.copytree(ROOT / "fixtures" / "workspace", self.workspace,
                        dirs_exist_ok=True)
        lines = ["NOTE %04d: synthetic long note line %03d." % (i, i)
                 for i in range(1, 201)]
        (self.workspace / "long_notes.txt").write_text(
            "\n".join(lines) + "\n", encoding="utf-8")
        self.trace_dir = Path(tempfile.mkdtemp(prefix="mini-agent-m3-tr-"))

    def tearDown(self):
        shutil.rmtree(self.workspace, ignore_errors=True)
        shutil.rmtree(self.trace_dir, ignore_errors=True)

    def test_long_session_compresses_and_continues(self):
        threshold = self.task["threshold"]
        model = ScriptedModel(self.task["replies"])
        tools = ToolRegistry(self.workspace)
        messages = [system_msg(self.task["system_prompt"]),
                    user_msg(self.task["task"])]
        pipeline = CompressionPipeline([
            AgingCompressor(threshold),
            SummaryCompressor(threshold, model, keep_recent=4),
        ])
        events = []
        window_tokens = []
        window = ContextWindow(threshold, pipeline, observers=[
            lambda step, tokens, reports: (
                events.extend(report.strategy for report in reports),
                window_tokens.append(tokens))])
        trace_path = self.trace_dir / "m3.jsonl"
        with Tracer(trace_path) as tracer:
            answer = run_loop(model, tools, messages, tracer,
                              max_steps=len(self.task["replies"]) + 2,
                              context_window=window)
        self.assertIn("M3 长会话任务完成", answer)
        self.assertIn("tool_result_aging", events)
        # 阈值约束的是每轮发给模型前的窗口，逐轮观测值都不得越线
        self.assertTrue(window_tokens)
        self.assertTrue(all(tokens <= threshold for tokens in window_tokens))
        records = [json.loads(line)
                   for line in trace_path.read_text(encoding="utf-8").splitlines()]
        compression_events = [r for r in records
                              if r.get("event") == "context_compression"]
        self.assertTrue(compression_events)
        for record in compression_events:
            payload = record["payload"]
            self.assertLessEqual(payload["after_tokens"],
                                 payload["before_tokens"])
        # 摘要消息出现后，对话仍继续并正常收尾
        roles = [msg["role"] for msg in messages]
        self.assertEqual(roles[-1], "assistant")
        self.assertTrue(any("【早期会话摘要】" in (msg.get("content") or "")
                            for msg in messages)
                        or any("【工具结果已老化】" in (msg.get("content") or "")
                               for msg in messages))


if __name__ == "__main__":
    unittest.main()
