"""headless 测试：不依赖 TTY、不依赖外部 API。

测试直接走 run_loop 公共入口，断言：
1. M1 任务能完整跑通，最终回复不含工具调用；
2. edit_file 真实改了文件，测试在修改后通过；
3. edit_file 的唯一性保护与路径越界保护生效；
4. trace 文件按消息逐条落盘。
"""

import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from mini_agent import ScriptedModel, ToolRegistry, Tracer, run_loop
from mini_agent.messages import system_msg, user_msg


def load_task():
    return json.loads((ROOT / "scripts" / "m1_task.json").read_text(encoding="utf-8"))


def fresh_workspace():
    tmp = Path(tempfile.mkdtemp(prefix="mini-agent-ws-"))
    shutil.copytree(ROOT / "fixtures" / "workspace", tmp, dirs_exist_ok=True)
    return tmp


class LoopM1Test(unittest.TestCase):
    def setUp(self):
        self.task = load_task()
        self.workspace = fresh_workspace()
        self.tmp_trace = Path(tempfile.mkdtemp(prefix="mini-agent-tr-")) / "trace.jsonl"

    def tearDown(self):
        shutil.rmtree(self.workspace, ignore_errors=True)
        shutil.rmtree(self.tmp_trace.parent, ignore_errors=True)

    def _run(self):
        model = ScriptedModel(self.task["replies"])
        tools = ToolRegistry(self.workspace)
        messages = [system_msg("sys"), user_msg(self.task["task"])]
        with Tracer(self.tmp_trace) as tracer:
            answer = run_loop(model, tools, messages, tracer)
        return model, messages, answer

    def test_loop_completes_without_tool_calls(self):
        model, messages, answer = self._run()
        self.assertEqual(model.calls, 4)
        self.assertIn("测试全部通过", answer)
        self.assertNotIn("tool_calls", messages[-1])

    def test_file_really_fixed(self):
        self._run()
        source = (self.workspace / "calculator.py").read_text(encoding="utf-8")
        self.assertIn("return n * n", source)
        self.assertNotIn("return n + n", source)

    def test_trace_has_all_messages(self):
        self._run()
        lines = [json.loads(x) for x in self.tmp_trace.read_text(encoding="utf-8").splitlines()]
        msgs = [r for r in lines if r["type"] == "message"]
        # 3 条 assistant（带工具调用）+ 3 条 tool 结果 + 1 条最终 assistant = 7
        self.assertEqual(len(msgs), 7)
        self.assertEqual([m["message"]["role"] for m in msgs],
                         ["assistant", "tool", "assistant", "tool",
                          "assistant", "tool", "assistant"])

    def test_edit_rejects_non_unique(self):
        tools = ToolRegistry(self.workspace)
        result = tools.dispatch("edit_file", {
            "path": "calculator.py", "old_string": "n", "new_string": "x"})
        self.assertFalse(result.ok)
        self.assertIn("不唯一", result.content)

    def test_read_rejects_path_escape(self):
        tools = ToolRegistry(self.workspace)
        result = tools.dispatch("read_file", {"path": "../../etc/hosts"})
        self.assertFalse(result.ok)


if __name__ == "__main__":
    unittest.main()
