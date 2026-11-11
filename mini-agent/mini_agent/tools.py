"""工具声明、参数校验、真实执行与结构化错误。

M1 的 read_file/edit_file/run_test 调用方式保持不变。M2 增加三个只读
工具，并把所有工具的 JSON Schema 声明集中进注册表。
"""

import copy
import subprocess
from concurrent.futures import ThreadPoolExecutor

from .schema import SchemaError, parse_and_validate


def _object(properties, required=None):
    return {
        "type": "object",
        "properties": properties,
        "required": required or [],
        "additionalProperties": False,
    }


class ToolResult(object):
    def __init__(self, ok, content, error=None):
        self.ok = ok
        self.content = content
        self.error = error

    def to_dict(self):
        result = {"ok": self.ok, "content": self.content}
        if self.error is not None:
            result["error"] = self.error
        return result


class ToolRegistry(object):
    _SPECS = {
        "read_file": {
            "description": "读取工作区内一个 UTF-8 文本文件。",
            "readonly": True,
            "parameters": _object({"path": {"type": "string", "minLength": 1}}, ["path"]),
        },
        "edit_file": {
            "description": "精确替换唯一命中的 old_string。",
            "readonly": False,
            "parameters": _object({
                "path": {"type": "string", "minLength": 1},
                "old_string": {"type": "string", "minLength": 1},
                "new_string": {"type": "string"},
            }, ["path", "old_string", "new_string"]),
        },
        "run_test": {
            "description": "在工作区运行 unittest 并返回退出码与输出。",
            "readonly": False,
            "parameters": _object({}),
        },
        "list_files": {
            "description": "列出一个目录的直接子项，目录名以斜杠结尾。",
            "readonly": True,
            "parameters": _object({
                "path": {"type": "string", "default": "."},
                "max_entries": {"type": "integer", "minimum": 1, "maximum": 200, "default": 50},
            }),
        },
        "search_text": {
            "description": "在文本文件中搜索字面字符串并返回文件、行号和行内容。",
            "readonly": True,
            "parameters": _object({
                "query": {"type": "string", "minLength": 1},
                "path": {"type": "string", "default": "."},
                "max_matches": {"type": "integer", "minimum": 1, "maximum": 200, "default": 20},
            }, ["query"]),
        },
        "read_lines": {
            "description": "按一基行号读取文件的闭区间，减少不必要的长文件回流。",
            "readonly": True,
            "parameters": _object({
                "path": {"type": "string", "minLength": 1},
                "start_line": {"type": "integer", "minimum": 1, "default": 1},
                "end_line": {"type": "integer", "minimum": 1},
            }, ["path"]),
        },
    }

    def __init__(self, workspace, python_bin="python3", max_bytes=65536):
        self.workspace = workspace
        self.python_bin = python_bin
        self.max_bytes = max_bytes

    def definitions(self):
        """返回可发给模型的 function calling 工具声明的防御性副本。"""
        answer = []
        for name, spec in self._SPECS.items():
            answer.append({
                "name": name,
                "description": spec["description"],
                "readonly": spec["readonly"],
                "parameters": copy.deepcopy(spec["parameters"]),
            })
        return answer

    def is_readonly(self, name):
        spec = self._SPECS.get(name)
        return bool(spec and spec["readonly"])

    def dispatch_many(self, calls):
        """整批只读调用并发执行；结果始终按请求顺序返回。"""
        if len(calls) > 1 and all(self.is_readonly(call["name"]) for call in calls):
            with ThreadPoolExecutor(max_workers=len(calls)) as pool:
                futures = [pool.submit(self.dispatch, call["name"], call["arguments"]) for call in calls]
                return [future.result() for future in futures]
        return [self.dispatch(call["name"], call["arguments"]) for call in calls]

    def _error(self, name, code, message, legacy_prefix=None):
        content = "ERROR: %s" % (legacy_prefix or message)
        return ToolResult(False, content, {"code": code, "message": message, "tool": name})

    def dispatch(self, name, arguments):
        spec = self._SPECS.get(name)
        if spec is None:
            return self._error(name, "unknown_tool", "未知工具: %s" % name,
                               "unknown tool: %s" % name)
        try:
            values = parse_and_validate(arguments, spec["parameters"])
        except SchemaError as exc:
            return self._error(name, exc.code, exc.message,
                               "bad arguments for %s: %s" % (name, exc.message))
        handler = getattr(self, name)
        try:
            return handler(**values)
        except (OSError, UnicodeError, subprocess.TimeoutExpired) as exc:
            return self._error(name, "execution_error", "%s: %s" % (type(exc).__name__, exc))

    def _resolve(self, path):
        # 禁止路径逃出 workspace：只允许纯相对路径，规范化后必须仍在工作区内。
        if not path or path.startswith("/") or ".." in path.split("/"):
            raise ValueError("非法路径（只允许工作区内的相对路径）: %r" % path)
        return self.workspace / path

    def read_file(self, path):
        try:
            target = self._resolve(path)
        except ValueError as exc:
            return self._error("read_file", "invalid_path", str(exc), str(exc))
        if not target.is_file():
            return self._error("read_file", "not_found", "文件不存在: %s" % path,
                               "文件不存在: %s" % path)
        data = target.read_text(encoding="utf-8")
        if len(data.encode("utf-8")) > self.max_bytes:
            return self._error("read_file", "too_large", "文件超过 %d 字节上限" % self.max_bytes,
                               "文件超过 %d 字节上限" % self.max_bytes)
        return ToolResult(True, data)

    def edit_file(self, path, old_string, new_string):
        try:
            target = self._resolve(path)
        except ValueError as exc:
            return self._error("edit_file", "invalid_path", str(exc), str(exc))
        if not target.is_file():
            return self._error("edit_file", "not_found", "文件不存在: %s" % path,
                               "文件不存在: %s" % path)
        source = target.read_text(encoding="utf-8")
        hits = source.count(old_string)
        if hits == 0:
            return self._error("edit_file", "no_match", "old_string 在文件中未找到",
                               "old_string 在文件中未找到")
        if hits > 1:
            return self._error("edit_file", "non_unique_match",
                               "old_string 命中 %d 处，替换不唯一" % hits,
                               "old_string 命中 %d 处，替换不唯一" % hits)
        target.write_text(source.replace(old_string, new_string, 1), encoding="utf-8")
        return ToolResult(True, "OK: 已替换 %s 中的 %d 处文本" % (path, 1))

    def run_test(self):
        proc = subprocess.run(
            [self.python_bin, "-m", "unittest", "-v"],
            cwd=str(self.workspace),
            capture_output=True,
            text=True,
            timeout=30,
        )
        output = proc.stdout + proc.stderr
        if proc.returncode == 0:
            return ToolResult(True, "EXIT 0\n" + output)
        return ToolResult(False, "EXIT %d\n%s" % (proc.returncode, output))

    def list_files(self, path=".", max_entries=50):
        try:
            target = self._resolve(path)
        except ValueError as exc:
            return self._error("list_files", "invalid_path", str(exc))
        if not target.is_dir():
            return self._error("list_files", "not_directory", "目录不存在: %s" % path)
        entries = sorted(target.iterdir(), key=lambda item: item.name)
        lines = [item.name + ("/" if item.is_dir() else "") for item in entries[:max_entries]]
        return ToolResult(True, "OK: %d 个条目\n%s" % (len(lines), "\n".join(lines)))

    def search_text(self, query, path=".", max_matches=20):
        try:
            target = self._resolve(path)
        except ValueError as exc:
            return self._error("search_text", "invalid_path", str(exc))
        if not target.exists():
            return self._error("search_text", "not_found", "路径不存在: %s" % path)
        if target.is_file():
            files = [target]
        else:
            suffixes = {".py", ".md", ".txt", ".json", ".toml", ".yaml", ".yml"}
            files = sorted(item for item in target.rglob("*")
                           if item.is_file() and item.suffix in suffixes)
        matches = []
        for item in files:
            for number, line in enumerate(item.read_text(encoding="utf-8").splitlines(), 1):
                if query in line:
                    matches.append("%s:%d:%s" % (item.relative_to(self.workspace), number, line))
                    if len(matches) >= max_matches:
                        return ToolResult(True, "OK: 已达到 %d 处匹配上限\n%s" %
                                          (max_matches, "\n".join(matches)))
        return ToolResult(True, "OK: %d 处匹配\n%s" % (len(matches), "\n".join(matches)))

    def read_lines(self, path, start_line=1, end_line=None):
        if end_line is not None and end_line < start_line:
            return self._error("read_lines", "invalid_range",
                               "end_line %d 小于 start_line %d" % (end_line, start_line))
        try:
            target = self._resolve(path)
        except ValueError as exc:
            return self._error("read_lines", "invalid_path", str(exc))
        if not target.is_file():
            return self._error("read_lines", "not_found", "文件不存在: %s" % path)
        lines = target.read_text(encoding="utf-8").splitlines()
        stop = len(lines) if end_line is None else min(end_line, len(lines))
        selected = lines[start_line - 1:stop]
        body = "\n".join("%4d  %s" % (number, line)
                         for number, line in enumerate(selected, start_line))
        return ToolResult(True, "OK: %s 第 %d-%d 行\n%s" %
                          (path, start_line, stop, body))
