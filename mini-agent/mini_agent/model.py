"""模型适配器。

M1 用 ScriptedModel：按对话步数返回预先录制的确定性回复，不访问任何
外部 API。它的价值是让实验可复现——同一条任务跑十次，消息序列完全
一致，trace 可以逐字节对拍。

适配器边界（complete 方法的签名与返回结构）对齐主流 chat completion
接口：输入完整消息列表，返回一条 assistant 消息。M2 接入真实模型时
只需新写一个同接口的实现，loop 与工具层不用改。
"""


class ScriptedModel(object):
    def __init__(self, script, system_prompt=""):
        # script 是一个回复列表，每项形如：
        # {"content": "...", "tool_calls": [...]}；按调用次序逐条返回。
        self._script = list(script)
        self._system_prompt = system_prompt
        self.calls = 0

    @property
    def system_prompt(self):
        return self._system_prompt

    def complete(self, messages):
        if self.calls >= len(self._script):
            raise RuntimeError("脚本回复已用尽，但 loop 仍未结束")
        recorded = self._script[self.calls]
        self.calls += 1
        # 安全断言：脚本第 N 步预期看到 N 条历史消息（含本轮将追加的结果）。
        # 真实模型没有这条约束；它在这里用来防止脚本与 loop 错位时静默跑偏。
        reply = {
            "role": "assistant",
            "content": recorded.get("content", ""),
        }
        if recorded.get("tool_calls"):
            reply["tool_calls"] = recorded["tool_calls"]
        return reply
