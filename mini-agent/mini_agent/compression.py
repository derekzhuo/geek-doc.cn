"""M3 上下文压缩：阈值触发、工具结果老化与滚动摘要。

设计边界（与 M1/M2 的消息模型对齐）：

- token 估算使用字符级确定性口径（见 estimate_tokens），不依赖分词器与
  外部 API，同一条消息跑十次结果完全一致，便于 trace 对拍；
- system 消息、首条 user 任务消息与最近 keep_recent 条尾部消息受保护，
  任何策略都不改动它们；
- 滚动摘要只替换「完整闭合」的 assistant(tool_calls) + tool 消息组，
  绝不留下没有 tool 消息配对的工具调用，也不移动 tool_call_id；
- 老化策略只缩短 tool 消息的 content，消息条数与配对关系不变，因此
  两种策略可以串成管道先老化、再摘要。
"""

import re
from dataclasses import dataclass, field

_CJK_RE = re.compile(r"[一-鿿　-〿＀-￯]")
_AGING_MARK = "【工具结果已老化】"
_SUMMARY_MARK = "【早期会话摘要】"


def estimate_tokens(messages):
    """字符级 token 估算。

    口径（教学工程的统一口径，不是某家分词器的精确实现）：
    - 每个 CJK 字符按 1 token 计，其余字符每 4 个折 1 token，向上取整；
    - 每条消息计 4 token 的角色与结构开销；
    - assistant 消息里的每个工具调用另计 8 token 加工具名长度，
      对应结构化字段本身也要占用窗口。
    """
    total = 0
    for msg in messages:
        total += 4
        text = msg.get("content") or ""
        cjk = len(_CJK_RE.findall(text))
        total += cjk + (len(text) - cjk + 3) // 4
        for call in msg.get("tool_calls") or []:
            total += 8 + len(call.get("name", ""))
    return total


@dataclass
class CompressionReport:
    """一次压缩的可观测记录，字段直接进 trace 事件。"""

    strategy: str
    before_messages: int
    after_messages: int
    before_tokens: int
    after_tokens: int
    affected: list = field(default_factory=list)

    def as_payload(self):
        return {
            "strategy": self.strategy,
            "before_messages": self.before_messages,
            "after_messages": self.after_messages,
            "before_tokens": self.before_tokens,
            "after_tokens": self.after_tokens,
            "affected_indexes": list(self.affected),
        }


class ContextOverflowError(RuntimeError):
    """窗口超限但已没有可压缩对象时抛出，对应真实产品的硬失败。"""


class AgingCompressor(object):
    """策略一：工具结果老化，保留首尾片段与结构摘要。

    截断不改变消息条数与配对关系，因此对任何位置的超长 tool 消息都生效，
    包括最新一条——单条回流本身过大时，「最近消息受保护」救不了窗口。
    system/user/assistant 消息永远不在本策略的处理范围内。
    """

    name = "tool_result_aging"

    def __init__(self, token_threshold,
                 min_content_len=240, head_chars=160, tail_chars=120):
        self.token_threshold = token_threshold
        self.min_content_len = min_content_len
        self.head_chars = head_chars
        self.tail_chars = tail_chars

    def maybe_compress(self, messages, tracer=None, step=0):
        before_tokens = estimate_tokens(messages)
        if before_tokens < self.token_threshold:
            return None
        affected = []
        for idx, msg in enumerate(messages):
            if msg.get("role") != "tool":
                continue
            content = msg.get("content") or ""
            if len(content) < self.min_content_len or content.startswith(_AGING_MARK):
                continue
            header = "%s 原 %d 字符 / %d 行" % (
                _AGING_MARK, len(content), len(content.splitlines()))
            if msg.get("error"):
                header += " / 错误码 %s" % msg["error"].get("code")
            msg["content"] = "\n".join([
                header,
                content[:self.head_chars],
                "……（中段已省略，完整内容见运行日志）……",
                content[-self.tail_chars:],
            ])
            affected.append(idx)
        if not affected:
            return None
        after_tokens = estimate_tokens(messages)
        report = CompressionReport(
            self.name, len(messages), len(messages),
            before_tokens, after_tokens, affected)
        if tracer is not None:
            tracer.event("context_compression", step=step, **report.as_payload())
        return report


class SummaryCompressor(object):
    """策略二：把早期闭合消息组滚动摘要成一条消息。

    summarizer 是模型适配器边界：教学工程用 ScriptedModel.summarize 产出
    确定性文本，接真实模型时换成一次 LLM 调用即可，本类不改动。
    """

    name = "rolling_summary"

    def __init__(self, token_threshold, summarizer, keep_recent=4):
        self.token_threshold = token_threshold
        self.summarizer = summarizer
        self.keep_recent = keep_recent

    def _protected_head(self, messages):
        """开头连续的 system 消息 + 第一条 user 任务消息始终保留。"""
        idx = 0
        while idx < len(messages) and messages[idx].get("role") == "system":
            idx += 1
        if idx < len(messages) and messages[idx].get("role") == "user":
            idx += 1
        return idx

    def _closed_region(self, messages, start, end):
        """收窄出一个只含完整 assistant/tool 配对组的区间。"""
        call_ids = set()
        for msg in messages[start:end]:
            for call in msg.get("tool_calls") or []:
                call_ids.add(call["id"])
        answered = {
            msg.get("tool_call_id")
            for msg in messages[start:end]
            if msg.get("role") == "tool"
        }
        # 区间内的每个调用都必须在区间内有 tool 回答，且每条 tool 消息
        # 都能在区间内找到它对应的调用；否则从尾部逐条收窄。
        while end > start and (call_ids != answered or any(
                msg.get("role") not in ("assistant", "tool")
                for msg in messages[start:end])):
            end -= 1
            call_ids = set()
            for msg in messages[start:end]:
                for call in msg.get("tool_calls") or []:
                    call_ids.add(call["id"])
            answered = {
                msg.get("tool_call_id")
                for msg in messages[start:end]
                if msg.get("role") == "tool"
            }
        return end

    def maybe_compress(self, messages, tracer=None, step=0):
        before_tokens = estimate_tokens(messages)
        if before_tokens < self.token_threshold:
            return None
        start = self._protected_head(messages)
        end = self._closed_region(
            messages, start, max(start, len(messages) - self.keep_recent))
        if end <= start:
            return None
        chunk = messages[start:end]
        summary_text = self.summarizer.summarize(chunk)
        summary_msg = {
            "role": "user",
            "content": "%s（由 harness 把 %d 条早期消息压缩而成）\n%s"
                       % (_SUMMARY_MARK, len(chunk), summary_text),
        }
        messages[start:end] = [summary_msg]
        if tracer is not None:
            tracer.message(summary_msg)
        after_tokens = estimate_tokens(messages)
        report = CompressionReport(
            self.name, len(chunk) + 1, len(messages),
            before_tokens, after_tokens, list(range(start, end)))
        if tracer is not None:
            tracer.event("context_compression", step=step, **report.as_payload())
        return report


class CompressionPipeline(object):
    """按顺序尝试多个策略，收集本轮全部生效的压缩报告。"""

    def __init__(self, compressors):
        self.compressors = list(compressors)

    def maybe_compress(self, messages, tracer=None, step=0):
        reports = []
        for compressor in self.compressors:
            report = compressor.maybe_compress(messages, tracer=tracer, step=step)
            if report is not None:
                reports.append(report)
        return reports or None


class ContextWindow(object):
    """loop 在每轮模型调用前看到的唯一入口：超限就压，压不动就硬失败。"""

    def __init__(self, token_threshold, pipeline, observers=None):
        self.token_threshold = token_threshold
        self.pipeline = pipeline
        self.observers = observers or []

    def before_model_call(self, messages, tracer, step):
        reports = self.pipeline.maybe_compress(messages, tracer=tracer, step=step) or []
        tokens = estimate_tokens(messages)
        if not reports and tokens > self.token_threshold:
            raise ContextOverflowError(
                "上下文 %d token 超过阈值 %d，且没有可压缩的消息组"
                % (tokens, self.token_threshold))
        for observer in self.observers:
            observer(step, tokens, reports)
        return reports
