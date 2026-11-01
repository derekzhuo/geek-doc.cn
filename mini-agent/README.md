# mini-agent：从零解剖 coding agent 的最小可运行工程

**对应教程**：[M1 Agent Loop 解剖](https://geek-doc.cn/ai-tools/agent-internals/agent-loop-anatomy.html)（上线后生效）；[M2 function calling 工具系统](https://geek-doc.cn/ai-tools/agent-internals/agent-tool-system.html)（上线后生效）

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

## 运行

```bash
make run      # M1：读文件 -> 改代码 -> 跑测试
make run-m2   # M2：只读并发 -> 错误恢复 -> 修复 -> 测试
make test     # M1 + M2 全部 headless 单元测试
```

只依赖 `python3`（3.8+），无需安装任何第三方包。

## 目录

| 路径 | 职责 |
|---|---|
| `mini_agent/loop.py` | agent loop 主循环 |
| `mini_agent/model.py` | 模型适配器（M1 为脚本化实现） |
| `mini_agent/tools.py` | 六个工具、注册表、并发执行与结构化错误 |
| `mini_agent/schema.py` | 工具参数使用的 JSON Schema 子集校验器 |
| `mini_agent/messages.py` | 消息结构（system/user/assistant/tool） |
| `mini_agent/trace.py` | JSONL trace |
| `scripts/m1_task.json` | M1 任务与录制回复 |
| `scripts/m2_task.json` | M2 只读并发与错误恢复任务 |
| `fixtures/workspace/` | 被测工程的干净模板（运行前复制到 `workspace/`） |
| `tests/` | headless 测试 |

## 后续里程碑边界

M3 上下文压缩、M4 子代理编排、M5 hooks、M6 权限沙箱，
继续在模型适配器与工具注册表的边界上增量演进。
