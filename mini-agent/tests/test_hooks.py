"""M5 钩子机制的 headless 测试。

覆盖：pre 拒绝短路且无副作用、ask 无人值守按拒绝处理、参数改写、
post 审计（含拒绝事件）、结果脱敏、只读批次并发同样过钩子、
多 pre 钩子按注册顺序短路。
"""

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from mini_agent.hooks import (  # noqa: E402
    ArgumentRewrite,
    AuditLog,
    HookedToolRegistry,
    PermissionPolicy,
    RedactSecrets,
)

SECRET_BODY = "name = demo\n# SECRET token=abc123\nVALUE = 1\n"


def make_workspace():
    tmp = Path(tempfile.mkdtemp(prefix="mini-agent-m5-"))
    (tmp / "config.py").write_text(SECRET_BODY, encoding="utf-8")
    for i in range(25):
        (tmp / ("file%02d.txt" % i)).write_text("x", encoding="utf-8")
    return tmp


def deny_config(name, path):
    if "config.py" in path:
        return "config.py 受保护，禁止编辑"
    return ""


class PreHookTest(unittest.TestCase):
    def setUp(self):
        self.workspace = make_workspace()
        self.addCleanup(shutil.rmtree, self.workspace)

    def test_deny_short_circuits_without_side_effect(self):
        audit = []
        registry = HookedToolRegistry(
            self.workspace,
            pre_hooks=[PermissionPolicy(path_rules=[deny_config])],
            post_hooks=[AuditLog(audit)])
        result = registry.dispatch("edit_file", {
            "path": "config.py",
            "old_string": "VALUE = 1",
            "new_string": "VALUE = 99",
        })
        self.assertFalse(result.ok)
        self.assertEqual(result.error["code"], "hook_denied")
        self.assertIn("受保护", result.error["message"])
        # 拒绝必须零副作用：文件内容原封不动。
        self.assertIn("VALUE = 1",
                      (self.workspace / "config.py").read_text(encoding="utf-8"))
        # 拒绝事件照样进审计。
        self.assertEqual(len(audit), 1)
        self.assertEqual(audit[0]["tool"], "edit_file")
        self.assertFalse(audit[0]["ok"])

    def test_allow_path_goes_through(self):
        registry = HookedToolRegistry(
            self.workspace,
            pre_hooks=[PermissionPolicy(path_rules=[deny_config])])
        result = registry.dispatch("edit_file", {
            "path": "file01.txt",
            "old_string": "x",
            "new_string": "yy",
        })
        self.assertTrue(result.ok)
        self.assertEqual((self.workspace / "file01.txt").read_text(
            encoding="utf-8"), "yy")

    def test_ask_mode_denies_headless(self):
        registry = HookedToolRegistry(
            self.workspace,
            pre_hooks=[PermissionPolicy(modes={"run_test": "ask"})])
        result = registry.dispatch("run_test", {})
        self.assertFalse(result.ok)
        self.assertEqual(result.error["code"], "hook_denied")
        self.assertIn("人工确认", result.error["message"])

    def test_argument_rewrite_clamps_listing(self):
        registry = HookedToolRegistry(
            self.workspace,
            pre_hooks=[ArgumentRewrite(max_entries_cap=20)])
        result = registry.dispatch("list_files",
                                   {"path": ".", "max_entries": 100})
        self.assertTrue(result.ok)
        # 工作区有 26 个条目，未改写会返回 26 行；被钩子收敛到 20。
        self.assertIn("20 个条目", result.content)
        self.assertNotIn("file24.txt", result.content)

    def test_hook_chain_order_and_short_circuit(self):
        calls = []

        class RecordHook(PermissionPolicy):
            def before(self, name, arguments):
                calls.append(name)
                return super().before(name, arguments)

        registry = HookedToolRegistry(
            self.workspace,
            pre_hooks=[
                RecordHook(modes={}),
                RecordHook(modes={"edit_file": "deny"}),
                RecordHook(modes={}),
            ])
        result = registry.dispatch("edit_file", {
            "path": "file01.txt", "old_string": "x", "new_string": "y"})
        self.assertFalse(result.ok)
        # 第二个钩子拒绝后第三个不得再执行。
        self.assertEqual(calls, ["edit_file", "edit_file"])


class PostHookTest(unittest.TestCase):
    def setUp(self):
        self.workspace = make_workspace()
        self.addCleanup(shutil.rmtree, self.workspace)

    def test_redact_secret_line_in_result(self):
        registry = HookedToolRegistry(
            self.workspace,
            post_hooks=[RedactSecrets()])
        result = registry.dispatch("read_file", {"path": "config.py"})
        self.assertTrue(result.ok)
        self.assertNotIn("abc123", result.content)
        self.assertIn("******", result.content)
        # 脱敏只改回流给模型的内容，磁盘文件不动。
        self.assertIn("abc123",
                      (self.workspace / "config.py").read_text(encoding="utf-8"))

    def test_readonly_batch_also_passes_hooks(self):
        audit = []
        registry = HookedToolRegistry(
            self.workspace,
            pre_hooks=[ArgumentRewrite(max_entries_cap=10)],
            post_hooks=[AuditLog(audit)])
        calls = [
            {"id": "c1", "name": "list_files",
             "arguments": {"path": ".", "max_entries": 50}},
            {"id": "c2", "name": "read_file",
             "arguments": {"path": "config.py"}},
        ]
        results = registry.dispatch_many(calls)
        self.assertEqual(len(results), 2)
        self.assertTrue(all(r.ok for r in results))
        self.assertIn("10 个条目", results[0].content)
        # 并发执行下审计落盘顺序不保证，只校验集合与条数。
        self.assertEqual(sorted(row["tool"] for row in audit),
                         ["list_files", "read_file"])


if __name__ == "__main__":
    unittest.main()
