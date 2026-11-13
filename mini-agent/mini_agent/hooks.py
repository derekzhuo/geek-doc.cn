"""M5 工具调用钩子：在工具真正执行前后插入可编排的拦截点。

设计边界（与 M1-M4 的消息模型对齐）：

- pre 钩子在参数校验之后、工具 handler 之前运行，可以放行、改写参数或
  直接拒绝；拒绝不产生任何真实副作用，按 M2 的结构化错误口径回一条
  ToolResult，模型在下一轮能读到拒绝原因并自行改道；
- post 钩子在工具返回之后、结果进消息历史之前运行，可以只做审计，
  也可以改写返回内容（例如脱敏）；
- HookedToolRegistry 只包装 dispatch 一个方法：dispatch_many 的并发
  路径内部调用的仍是 self.dispatch，所以只读批次并发同样过钩子，
  run_loop 一行不改；
- 钩子链按注册顺序执行：任一 pre 钩子拒绝即短路，post 钩子串行接力，
  前一个的输出是后一个的输入。

教学模型的边界：ask 策略在无人值守场景下按拒绝处理并记录原因，
真实 harness 在这里会弹确认框等人的输入。
"""

import json
from dataclasses import dataclass, field

from .tools import ToolRegistry, ToolResult

HOOK_DENIED = "hook_denied"


@dataclass
class PreVerdict:
    """pre 钩子的裁决：放行（可附带改写后的参数）或拒绝（附原因）。"""

    allowed: bool
    arguments: dict = None
    reason: str = ""

    @classmethod
    def pass_(cls, arguments=None):
        return cls(True, arguments=arguments)

    @classmethod
    def deny(cls, reason):
        return cls(False, reason=reason)


class PreHook(object):
    def before(self, name, arguments):
        raise NotImplementedError

    def __call__(self, name, arguments):
        return self.before(name, arguments)


class PostHook(object):
    def after(self, name, arguments, result):
        raise NotImplementedError

    def __call__(self, name, arguments, result):
        return self.after(name, arguments, result)


class PermissionPolicy(PreHook):
    """按工具名与参数谓词决定放行/拒绝/询问的策略钩子。

    modes 把工具名映射到 allow / deny / ask 三种策略；path_rules 给
    写操作额外的路径谓词（返回拒绝原因字符串，返回空串表示放行）。
    """

    WRITE_TOOLS = frozenset({"edit_file", "run_test"})

    def __init__(self, modes=None, path_rules=None):
        self.modes = dict(modes or {})
        self.path_rules = list(path_rules or [])

    def before(self, name, arguments):
        mode = self.modes.get(name, "allow")
        if mode == "deny":
            return PreVerdict.deny("策略禁止调用工具 %s" % name)
        if mode == "ask":
            # 无人值守不挂起会话：按拒绝处理，原因里写明本应询问。
            return PreVerdict.deny("工具 %s 需要人工确认，无人值守下自动拒绝" % name)
        if name in self.WRITE_TOOLS:
            path = arguments.get("path", "")
            for rule in self.path_rules:
                reason = rule(name, path)
                if reason:
                    return PreVerdict.deny(reason)
        return PreVerdict.pass_()


class ArgumentRewrite(PreHook):
    """参数改写钩子示例：把 list_files 的 max_entries 收敛到上限内。"""

    def __init__(self, max_entries_cap=20):
        self.max_entries_cap = max_entries_cap

    def before(self, name, arguments):
        if name == "list_files":
            rewritten = dict(arguments)
            value = rewritten.get("max_entries", 50)
            if value > self.max_entries_cap:
                rewritten["max_entries"] = self.max_entries_cap
            return PreVerdict.pass_(rewritten)
        return PreVerdict.pass_()


class AuditLog(PostHook):
    """审计钩子：每次工具调用落一行 JSON，拒绝事件也记录。"""

    def __init__(self, sink):
        # sink 可以是文件路径，也可以是有 append 方法的列表（测试用）。
        self.sink = sink
        self._path = sink if isinstance(sink, str) else None

    def _emit(self, record):
        if self._path:
            with open(self._path, "a", encoding="utf-8") as fh:
                fh.write(json.dumps(record, ensure_ascii=False) + "\n")
        else:
            self.sink.append(record)

    def after(self, name, arguments, result):
        self._emit({
            "tool": name,
            "ok": result.ok,
            "error": result.error,
            "arguments": arguments,
        })
        return result


class RedactSecrets(PostHook):
    """结果脱敏钩子：把返回内容里带标记的整行替换成掩码。"""

    def __init__(self, marker="SECRET", mask="******"):
        self.marker = marker
        self.mask = mask

    def after(self, name, arguments, result):
        if not result.ok or self.marker not in result.content:
            return result
        lines = [self.mask if self.marker in line else line
                 for line in result.content.splitlines()]
        return ToolResult(True, "\n".join(lines))


class HookedToolRegistry(ToolRegistry):
    """在 M2 注册表之外包一条钩子链，工具定义与 handler 全部复用。"""

    def __init__(self, workspace, pre_hooks=None, post_hooks=None, **kwargs):
        super().__init__(workspace, **kwargs)
        self.pre_hooks = list(pre_hooks or [])
        self.post_hooks = list(post_hooks or [])
        self.denied = []

    def add_pre_hook(self, hook):
        self.pre_hooks.append(hook)

    def add_post_hook(self, hook):
        self.post_hooks.append(hook)

    def dispatch(self, name, arguments):
        current = dict(arguments)
        for hook in self.pre_hooks:
            verdict = hook(name, current)
            if not verdict.allowed:
                denied = self._error(name, HOOK_DENIED, verdict.reason,
                                     verdict.reason)
                self.denied.append({"tool": name, "reason": verdict.reason})
                for post in self.post_hooks:
                    denied = post(name, current, denied)
                return denied
            if verdict.arguments is not None:
                current = verdict.arguments
        result = super().dispatch(name, current)
        for hook in self.post_hooks:
            result = hook(name, current, result)
        return result
