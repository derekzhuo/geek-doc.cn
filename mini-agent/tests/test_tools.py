"""M2 工具系统与完整 loop 的 headless 回归测试。"""

import json
import shutil
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from mini_agent import ScriptedModel, ToolRegistry, Tracer, run_loop
from mini_agent.messages import system_msg, user_msg


def fresh_workspace():
    tmp = Path(tempfile.mkdtemp(prefix="mini-agent-m2-ws-"))
    shutil.copytree(ROOT / "fixtures" / "workspace", tmp, dirs_exist_ok=True)
    return tmp


class ToolSchemaTest(unittest.TestCase):
    def setUp(self):
        self.workspace = fresh_workspace()
        self.tools = ToolRegistry(self.workspace)

    def tearDown(self):
        shutil.rmtree(self.workspace, ignore_errors=True)

    def test_definitions_expose_six_tools(self):
        definitions = self.tools.definitions()
        self.assertEqual(len(definitions), 6)
        self.assertEqual({item["name"] for item in definitions},
                         {"read_file", "edit_file", "run_test",
                          "list_files", "search_text", "read_lines"})
        self.assertTrue(all("parameters" in item for item in definitions))

    def test_defaults_are_applied(self):
        result = self.tools.dispatch("list_files", {})
        self.assertTrue(result.ok)
        self.assertIn("calculator.py", result.content)
        self.assertIn("test_calculator.py", result.content)

    def test_missing_required_argument_is_structured_error(self):
        result = self.tools.dispatch("read_file", {})
        self.assertFalse(result.ok)
        self.assertEqual(result.error["code"], "schema_validation")
        self.assertIn("path", result.error["message"])

    def test_undeclared_argument_is_rejected(self):
        result = self.tools.dispatch("read_file", {"path": "calculator.py", "extra": 1})
        self.assertFalse(result.ok)
        self.assertIn("未声明参数", result.content)

    def test_wrong_type_and_range_are_rejected(self):
        wrong = self.tools.dispatch("list_files", {"max_entries": "10"})
        invalid = self.tools.dispatch("list_files", {"max_entries": 0})
        self.assertEqual(wrong.error["code"], "schema_validation")
        self.assertEqual(invalid.error["code"], "schema_validation")

    def test_invalid_json_is_distinguished_from_schema_error(self):
        result = self.tools.dispatch("read_lines", "{not-json}")
        self.assertFalse(result.ok)
        self.assertEqual(result.error["code"], "invalid_json")

    def test_json_string_arguments_are_accepted(self):
        result = self.tools.dispatch("read_lines",
                                     '{"path":"calculator.py","start_line":4,"end_line":6}')
        self.assertTrue(result.ok)
        self.assertIn("return n + n", result.content)

    def test_search_text_returns_file_line_and_content(self):
        result = self.tools.dispatch("search_text", {"query": "def square"})
        self.assertTrue(result.ok)
        self.assertIn("calculator.py:4:def square(n):", result.content)

    def test_read_lines_rejects_inverted_range_without_crashing(self):
        result = self.tools.dispatch("read_lines", {
            "path": "calculator.py", "start_line": 6, "end_line": 2})
        self.assertFalse(result.ok)
        self.assertEqual(result.error["code"], "invalid_range")
        self.assertEqual(result.error["tool"], "read_lines")

    def test_unknown_tool_has_stable_error_code(self):
        result = self.tools.dispatch("delete_everything", {})
        self.assertFalse(result.ok)
        self.assertEqual(result.error["code"], "unknown_tool")


class SlowReadRegistry(ToolRegistry):
    """用真实线程重叠而非耗时断言验证只读并发。"""

    def __init__(self, workspace):
        super().__init__(workspace)
        self.active = 0
        self.max_active = 0
        self.lock = threading.Lock()

    def read_file(self, path):
        with self.lock:
            self.active += 1
            self.max_active = max(self.max_active, self.active)
        time.sleep(0.05)
        with self.lock:
            self.active -= 1
        return super().read_file(path)


class ParallelAndLoopTest(unittest.TestCase):
    def setUp(self):
        self.workspace = fresh_workspace()

    def tearDown(self):
        shutil.rmtree(self.workspace, ignore_errors=True)

    def test_three_readonly_calls_overlap_and_keep_order(self):
        tools = SlowReadRegistry(self.workspace)
        calls = [{"id": str(i), "name": "read_file", "arguments": {"path": "calculator.py"}}
                 for i in range(3)]
        results = tools.dispatch_many(calls)
        self.assertEqual(tools.max_active, 3)
        self.assertEqual(len(results), 3)
        self.assertTrue(all(result.ok for result in results))

    def test_m2_loop_recovers_from_error_and_finishes(self):
        task = json.loads((ROOT / "scripts" / "m2_task.json").read_text(encoding="utf-8"))
        model = ScriptedModel(task["replies"])
        tools = ToolRegistry(self.workspace)
        messages = [system_msg(task["system_prompt"]), user_msg(task["task"])]
        trace_dir = Path(tempfile.mkdtemp(prefix="mini-agent-m2-tr-"))
        try:
            with Tracer(trace_dir / "trace.jsonl") as tracer:
                answer = run_loop(model, tools, messages, tracer)
            records = [json.loads(line) for line in
                       (trace_dir / "trace.jsonl").read_text(encoding="utf-8").splitlines()]
        finally:
            shutil.rmtree(trace_dir, ignore_errors=True)
        tool_messages = [message for message in messages if message["role"] == "tool"]
        self.assertEqual(model.calls, 6)
        self.assertEqual(len(tool_messages), 7)
        self.assertEqual(tool_messages[3]["error"]["code"], "invalid_range")
        self.assertTrue(any(record.get("event") == "tool_batch" and
                            record["payload"]["mode"] == "parallel" for record in records))
        self.assertIn("测试全部通过", answer)
        self.assertIn("return n * n", (self.workspace / "calculator.py").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
