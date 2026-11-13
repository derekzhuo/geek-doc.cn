"""mini-agent：可增量演进的最小 coding agent 教学工程。

M1 只包含：消息抽象、脚本化模型适配器、read/edit/run_test 三个工具、
agent loop 主循环与 JSONL trace。后续里程碑在这些边界上增量扩展。
"""

from .compression import (
    AgingCompressor,
    CompressionPipeline,
    ContextOverflowError,
    ContextWindow,
    SummaryCompressor,
    estimate_tokens,
)
from .hooks import (
    ArgumentRewrite,
    AuditLog,
    HookedToolRegistry,
    PermissionPolicy,
    PreVerdict,
    RedactSecrets,
)
from .loop import run_loop
from .messages import assistant_msg, tool_msg, user_msg
from .model import ScriptedModel
from .subagent import (
    ForkingToolRegistry,
    MemoryTracer,
    SubagentJob,
    SubagentOrchestrator,
    SubagentResult,
    SubagentRunner,
    aggregate,
)
from .tools import ToolRegistry
from .trace import Tracer

__all__ = [
    "run_loop",
    "user_msg",
    "assistant_msg",
    "tool_msg",
    "ScriptedModel",
    "ToolRegistry",
    "HookedToolRegistry",
    "PermissionPolicy",
    "ArgumentRewrite",
    "AuditLog",
    "RedactSecrets",
    "PreVerdict",
    "Tracer",
    "AgingCompressor",
    "SummaryCompressor",
    "CompressionPipeline",
    "ContextWindow",
    "ContextOverflowError",
    "estimate_tokens",
    "SubagentJob",
    "SubagentResult",
    "SubagentRunner",
    "SubagentOrchestrator",
    "ForkingToolRegistry",
    "MemoryTracer",
    "aggregate",
]
