# codex-agents-md-nested-rules — 多级 AGENTS.md 嵌套优先级实测

**对应教程**：<https://geek-doc.cn/ai-tools/codex/codex-agents-md-nested-rules.html>（规划篇目，上线后此链接即生效）

在一个三层嵌套的临时仓库里逐级放置 AGENTS.md，用只输出标记的 prompt 验证 Codex 实际遵循哪一级规则，以及显式指令与仓库规则冲突时的优先级。

## 文件

| 文件 | 作用 |
|---|---|
| `run.sh` | 构造 `根 / service / service/api` 三层 AGENTS.md，逐目录发起四组独立 Codex 会话 |
| `results/` | 真实运行输出：每组的 `case/rules/exit_code/final_answer` 字段与环境记录 |

## 复现（macOS，需已登录 Codex CLI）

脚本不内置任何凭据。每个案例使用独立临时 `CODEX_HOME`，认证二选一：

1. 已登录官方账号时放好 `~/.codex/auth.json`，脚本会自动复制进临时目录；
2. 使用第三方 model provider 时，把仅含连接配置的 config.toml 路径交给环境变量 `PROBE_PROVIDER_CONFIG`（默认读取 `~/.codex/arkcli.config.toml`），脚本复制后即作为临时目录的 config.toml，退出时随临时目录一起删除。

```bash
bash run.sh results
cat results/summary.log
```

四组案例分别覆盖：根规则生效、子目录覆盖、孙目录就近命中、显式 prompt 与规则文件冲突。每组独立进程、独立临时 `CODEX_HOME` 与系统临时目录，结束后自动清理，不读取或打印任何凭据。
