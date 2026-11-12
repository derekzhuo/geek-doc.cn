"""M4 子代理编排：主代理 fork 出独立上下文的子代理，结果回传父会话。

设计边界（与 M1-M3 的消息模型对齐）：

- 上下文隔离：子代理不从父会话继承任何消息正文，它的消息历史从一条
  system 消息和一条 user 任务消息重新开始；父会话只下发任务描述与一份
  共享只读输入（shared_inputs），子代理对父历史既不可见也不可修改；
- 独立运行：每个子代理持有自己的 ScriptedModel、消息列表、工具注册表
  与内存 trace，复用同一个 run_loop，机制与主代理完全相同；
- 结果回传：子代理跑完后只有「最终回复 + 自己的 trace 摘要 + 耗时」
  回到父会话，聚合成一条 tool 消息追加进父历史；子代理的中间消息
  （read_file 回流、edit 回报等）永远不进入父上下文；
- 失败不炸穿：子代理内部抛出的任何异常都被兜住，按 M2 的结构化错误
  口径回传 {code, message, subagent}，主 loop 可以据此决定重试或收尾；
- 并发模型：并行编排用 ThreadPoolExecutor，两个子代理改不同文件、
  各自持有独立注册表，不存在共享可变状态；父级 trace 的写入用锁保护。

教学模型的边界：ScriptedModel 的 delay 只模拟推理往返耗时，真实 API
里的提示词缓存命中、排队与网络抖动在这里都不存在，因此本篇只能测
「编排结构带来的墙钟时间差异」，不测缓存命中率。
"""

import threading
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field

from .loop import run_loop
from .messages import system_msg, user_msg
from .model import ScriptedModel
from .schema import parse_and_validate
from .tools import ToolRegistry, ToolResult

SUBAGENT_FAILED = "subagent_failed"

DEFAULT_SUB_SYSTEM = (
    "你是主代理 fork 出来的子代理，只在自己的独立上下文里工作。"
    "你看不到主代理与其他子代理的对话，只能依据任务描述与共享只读输入行事，"
    "完成后用一条最终文本汇报结果。"
)


class MemoryTracer(object):
    """与 Tracer 同接口的内存版 trace，子代理事件先全部落在自己的列表里。

    子代理不直接写父级 JSONL 文件：并行时多线程写同一个句柄会交错，
    且子代理的中间消息本就不该进父历史。运行结束后由编排器按需摘取。
    """

    def __init__(self):
        self.records = []

    def event(self, kind, **payload):
        self.records.append({"type": "event", "event": kind, "payload": payload})

    def message(self, message):
        self.records.append({"type": "message", "message": message})

    def close(self):
        pass

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.close()

    def messages(self):
        return [item["message"] for item in self.records if item["type"] == "message"]

    def events(self):
        return [item["payload"] for item in self.records if item["type"] == "event"]


@dataclass
class SubagentJob(object):
    """一次 fork 的任务描述：父会话只交出这些信息，不交出自己的历史。"""

    name: str
    task: str
    script: list
    shared_inputs: dict = field(default_factory=dict)
    system_prompt: str = ""
    max_steps: int = 8
    delay: float = 0.0


@dataclass
class SubagentResult(object):
    """子代理回传给编排器的全部内容，结构固定便于父侧聚合与断言。"""

    name: str
    ok: bool
    final_reply: str
    messages: list
    records: list
    elapsed: float
    error: object = None

    @property
    def rounds(self):
        return sum(1 for item in self.records
                   if item["type"] == "event" and item["event"] == "step_begin")

    def as_dict(self):
        data = {
            "name": self.name,
            "ok": self.ok,
            "final_reply": self.final_reply,
            "rounds": self.rounds,
            "elapsed": round(self.elapsed, 4),
            "message_count": len(self.messages),
        }
        if self.error is not None:
            data["error"] = self.error
        return data


class SubagentRunner(object):
    """负责把一个 SubagentJob 跑成一个 SubagentResult。

    parent_tracer 是父会话的 JSONL tracer，只接收 fork/return 两个生命周期
    事件；所有写入都过同一把锁，保证并行编排下 JSONL 不交错。
    """

    def __init__(self, workspace, parent_tracer, python_bin="python3"):
        self.workspace = workspace
        self.parent_tracer = parent_tracer
        self.python_bin = python_bin
        self._lock = threading.Lock()

    def _build_messages(self, job):
        # 上下文隔离的关键：子代理历史从空开始，只放 system 与一条 user。
        lines = ["子任务（来自主代理）：%s" % job.task, "", "共享只读输入："]
        if job.shared_inputs:
            for key, value in sorted(job.shared_inputs.items()):
                lines.append("- %s: %s" % (key, value))
        else:
            lines.append("- （无）")
        lines.append("")
        lines.append("约束：共享输入只读，不得修改；只操作任务点名的文件。")
        return [
            system_msg(job.system_prompt or DEFAULT_SUB_SYSTEM),
            user_msg("\n".join(lines)),
        ]

    def _emit(self, kind, **payload):
        with self._lock:
            self.parent_tracer.event(kind, **payload)

    def run(self, job):
        messages = self._build_messages(job)
        model = ScriptedModel(job.script,
                              system_prompt=job.system_prompt or DEFAULT_SUB_SYSTEM,
                              delay=job.delay)
        # 每个子代理拿到独立注册表：workspace 相同，但各自只改指派的文件。
        tools = ToolRegistry(self.workspace, python_bin=self.python_bin)
        tracer = MemoryTracer()
        self._emit("subagent_fork", name=job.name,
                   shared_keys=sorted(job.shared_inputs),
                   parent_history_visible=False)
        started = time.perf_counter()
        try:
            with tracer:
                answer = run_loop(model, tools, messages, tracer,
                                  max_steps=job.max_steps)
            result = SubagentResult(
                name=job.name, ok=True, final_reply=answer,
                messages=messages, records=tracer.records,
                elapsed=time.perf_counter() - started)
            self._emit("subagent_return", name=job.name, ok=True,
                       rounds=result.rounds,
                       elapsed=round(result.elapsed, 4),
                       message_count=len(messages))
        except Exception as exc:  # 子代理失败不允许炸穿主 loop
            error = {
                "code": SUBAGENT_FAILED,
                "message": "%s: %s" % (type(exc).__name__, exc),
                "subagent": job.name,
            }
            result = SubagentResult(
                name=job.name, ok=False, final_reply="",
                messages=messages, records=tracer.records,
                elapsed=time.perf_counter() - started, error=error)
            self._emit("subagent_return", name=job.name, ok=False,
                       rounds=result.rounds,
                       elapsed=round(result.elapsed, 4), error=error)
        return result


class SubagentOrchestrator(object):
    """串行与并行两种编排，返回同构的结果列表，墙钟时间分别计时。"""

    def __init__(self, runner):
        self.runner = runner

    def run_serial(self, jobs):
        started = time.perf_counter()
        results = [self.runner.run(job) for job in jobs]
        return results, time.perf_counter() - started

    def run_parallel(self, jobs, max_workers=None):
        started = time.perf_counter()
        workers = max_workers or len(jobs)
        with ThreadPoolExecutor(max_workers=workers) as pool:
            # 按提交顺序收集 future，结果顺序与 jobs 严格一致，
            # 与 M2 只读批次并发「按请求序回流」的约定保持同构。
            futures = [pool.submit(self.runner.run, job) for job in jobs]
            results = [future.result() for future in futures]
        return results, time.perf_counter() - started


def aggregate(results, mode, elapsed):
    """把多个子代理结果聚合成父会话里的一条 tool 消息正文。"""

    lines = ["子代理编排完成（%s，%d 个，%.3fs）"
             % (mode, len(results), elapsed)]
    for result in results:
        status = "成功" if result.ok else "失败"
        lines.append("")
        lines.append("[%s] 子代理 %s：%s，%d 轮，消息 %d 条，耗时 %.3fs"
                     % (status, result.name, status, result.rounds,
                        len(result.messages), result.elapsed))
        if result.ok:
            lines.append("  最终回复：%s" % result.final_reply)
        else:
            lines.append("  错误回传：%s" % result.error["message"])
    return "\n".join(lines)


class ForkingToolRegistry(ToolRegistry):
    """在 M2 工具注册表之上加一个 fork_subagents 编排工具。

    主代理的 loop 代码一行不改：它看到的仍是一次普通 function calling
    工具调用，只是这个「工具」的执行体是一整套子代理编排。
    """

    FORK_TOOL = "fork_subagents"

    def __init__(self, workspace, parent_tracer, job_catalog,
                 parallel=True, python_bin="python3"):
        super().__init__(workspace, python_bin=python_bin)
        self.job_catalog = dict(job_catalog)
        self.parallel = parallel
        self.orchestrator = SubagentOrchestrator(
            SubagentRunner(workspace, parent_tracer, python_bin=python_bin))
        self.last_results = []
        self.last_elapsed = None

    def definitions(self):
        specs = super().definitions()
        specs.append({
            "name": self.FORK_TOOL,
            "description": "fork 若干独立上下文的子代理并行或串行处理子任务。",
            "readonly": False,
            "parameters": {
                "type": "object",
                "properties": {
                    "jobs": {
                        "type": "array",
                        "items": {"type": "string", "minLength": 1},
                        "minItems": 1,
                        "maxItems": 4,
                    },
                },
                "required": ["jobs"],
                "additionalProperties": False,
            },
        })
        return specs

    def is_readonly(self, name):
        if name == self.FORK_TOOL:
            return False
        return super().is_readonly(name)

    def _fork(self, arguments):
        values = parse_and_validate(arguments, self.definitions()[-1]["parameters"])
        names = values["jobs"]
        missing = [name for name in names if name not in self.job_catalog]
        if missing:
            return self._error(self.FORK_TOOL, "unknown_subagent",
                               "未注册的子代理任务: %s" % ",".join(missing))
        jobs = [self.job_catalog[name] for name in names]
        mode = "parallel" if self.parallel else "serial"
        if self.parallel:
            results, elapsed = self.orchestrator.run_parallel(jobs)
        else:
            results, elapsed = self.orchestrator.run_serial(jobs)
        self.last_results = results
        self.last_elapsed = elapsed
        content = aggregate(results, mode, elapsed)
        if all(result.ok for result in results):
            return ToolResult(True, content)
        failed = [result.name for result in results if not result.ok]
        return ToolResult(False, content, {
            "code": SUBAGENT_FAILED,
            "message": "子代理失败: %s" % ",".join(failed),
            "tool": self.FORK_TOOL,
        })

    def dispatch(self, name, arguments):
        if name == self.FORK_TOOL:
            try:
                return self._fork(arguments)
            except Exception as exc:  # 编排层自身的参数/校验异常同样结构化
                return self._error(self.FORK_TOOL, "execution_error",
                                   "%s: %s" % (type(exc).__name__, exc))
        return super().dispatch(name, arguments)
