# mini-agent：从零解剖 coding agent 的最小可运行工程

**对应教程**：[M1 Agent Loop 解剖](https://geek-doc.cn/ai-tools/agent-internals/agent-loop-anatomy.html)（上线后生效）；[M2 function calling 工具系统](https://geek-doc.cn/ai-tools/agent-internals/agent-tool-system.html)（上线后生效）；[M3 上下文压缩机制](https://geek-doc.cn/ai-tools/agent-internals/agent-context-compression.html)（上线后生效）；[M4 子代理编排](https://geek-doc.cn/ai-tools/agent-internals/agent-subagent-fork.html)（上线后生效）

mini-agent 是一个只用 Python 3 标准库的教学工程，目标不是做产品，而是把
coding agent 的运行机制拆到能逐行读懂、逐消息追踪。

## M1：最小 agent loop

- 脚本化模型适配器 `ScriptedModel`：确定性回复，不依赖外部 API，实验可逐字节复现；
- 三个真实工具：`read_file` / `edit_file`（唯一匹配替换）/ `run_test`（unittest）；
- 主循环 `mini_agent/loop.py`（约 50 行）：模型决策 -> 工具执行 -> 结果回流；
- 全部消息落 `traces/trace.jsonl`，一行一个事件，可实时观察消息生命周期。

## M2：function calling 工具系统

- 在 M1 三个工具上新增 `list_files` / `search_text` / `read_lines`，六个工具都有 JSON Schema 声明；
- 同时接受 JSON object 与 JSON 字符串参数，校验必填项、类型、取值范围与未声明字段；
- 整批只读调用使用 `ThreadPoolExecutor` 并发执行，结果仍按请求顺序与 `tool_call_id` 配对；
- 错误以 `{code, message, tool}` 结构化回流，不把异常炸穿 loop；
- `make run` 保持 M1 演示不变，`make run-m2` 运行只读并发、错误恢复与修复测试的完整序列。

## M3：上下文压缩

- 新增 `mini_agent/compression.py`：字符级 token 估算、工具结果老化、滚动摘要、压缩管道与窗口阈值治理；
- 老化策略把超长 tool 消息截成「结构头 + 首部 + 省略标记 + 尾部」，消息条数与 `tool_call_id` 配对不变；
- 摘要策略只替换完整闭合的 assistant/tool 消息组，system 消息、首条 user 任务与最近 4 条尾部消息受保护；
- `ScriptedModel.summarize` 从消息内容产出确定性摘要，不访问外部 API；
- `scripts/drive_m3.py` 灌一条 13 次工具调用的长会话，对照不压缩基线与压缩管道，逐轮输出 token 表，落 `traces/m3-trace.jsonl` 与 `traces/m3-tokens.json`；
- `make run-m3` 跑长会话对照，`make test` 运行 M1 + M2 + M3 共 28 个 headless 用例。

## M4：子代理编排

- 新增 `mini_agent/subagent.py`：`SubagentJob`/`SubagentRunner`/`SubagentOrchestrator` 与 `ForkingToolRegistry`，主代理以一次 `fork_subagents` 工具调用 fork 子代理；
- 上下文隔离：子代理从一条 system 与一条 user 任务消息重新开始，只接收任务描述与共享只读输入，父历史正文不可见，子代理的中间消息也不进父会话；
- 结果回传：子代理跑完只把「最终回复 + 内存 trace 摘要 + 耗时」聚合成一条 tool 消息回到主 loop；失败按 `{code, message, subagent}` 结构化回传，不炸穿主 loop；
- 并行编排用 `ThreadPoolExecutor`，两个子代理各改一个文件，`time.perf_counter` 实测串行与并行墙钟时间，各重复 5 次取中位；
- `scripts/drive_m4.py` 跑完整 fork 演示与串并行计时，落 `traces/m4-trace.jsonl`、`traces/m4-benchmark.json` 与 `traces/m4-results.txt`；
- `make run-m4` 运行 M4 演示，`make test` 运行 M1 + M2 + M3 + M4 共 36 个 headless 用例。

## 运行

```bash
make run      # M1：读文件 -> 改代码 -> 跑测试
make run-m2   # M2：只读并发 -> 错误恢复 -> 修复 -> 测试
make run-m3   # M3：长会话压缩对照，逐轮 token 表与压缩事件
make run-m4   # M4：fork 两个子代理并行改文件，串并行计时对照
make test     # M1 + M2 + M3 + M4 全部 headless 单元测试
```

只依赖 `python3`（3.8+），无需安装任何第三方包。

## 目录

| 路径 | 职责 |
|---|---|
| `mini_agent/loop.py` | agent loop 主循环 |
| `mini_agent/model.py` | 模型适配器（M1 为脚本化实现） |
| `mini_agent/tools.py` | 六个工具、注册表、并发执行与结构化错误 |
| `mini_agent/schema.py` | 工具参数使用的 JSON Schema 子集校验器 |
| `mini_agent/compression.py` | M3 上下文压缩：token 估算、老化、滚动摘要与窗口治理 |
| `mini_agent/subagent.py` | M4 子代理编排：独立上下文 fork、聚合回传与串并行编排 |
| `mini_agent/messages.py` | 消息结构（system/user/assistant/tool） |
| `mini_agent/trace.py` | JSONL trace |
| `scripts/m1_task.json` | M1 任务与录制回复 |
| `scripts/m2_task.json` | M2 只读并发与错误恢复任务 |
| `scripts/m3_task.json` | M3 长会话任务脚本（13 次工具调用） |
| `scripts/drive_m3.py` | M3 长会话压缩对照驱动，产出 token 数据与 trace |
| `scripts/m4_task.json` | M4 双子代理任务脚本（两个文件各自的改动序列） |
| `scripts/drive_m4.py` | M4 fork 演示与串并行计时驱动，产出 benchmark 数据 |
| `fixtures/workspace/` | 被测工程的干净模板（运行前复制到 `workspace/`） |
| `tests/` | headless 测试 |

## 后续里程碑边界

M5 hooks、M6 权限沙箱，
继续在模型适配器与工具注册表的边界上增量演进。
