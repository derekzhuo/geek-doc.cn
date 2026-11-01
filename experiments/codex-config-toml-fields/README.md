# Codex config.toml 八字段探针

**对应教程**：https://geek-doc.cn/ai-tools/codex/codex-config-toml-fields.html（上线后生效）

本目录对应当前机器上的 Codex CLI 0.156.1，包含八个字段的改后样例、严格配置检查脚本、通知接收脚本和真实输出。

## 文件

- `before.toml`：不显式设置八字段的基线。
- `after.toml`：模型、推理档位、审批、沙箱、通知、历史、TUI 与搜索的改后样例。
- `probe.sh`：生成当前二进制的协议 schema，并逐项用 `--strict-config` 验证。
- `notify.sh`：把 Codex 传入的最后一条 JSON 通知写入独立 `CODEX_HOME`。
- `output/`：2026-11-01 的离线 schema 与严格配置检查结果，临时路径已脱敏。

## 复现

只做离线检查：

```bash
bash probe.sh offline.log
```

还要观察启动头时，从自己的 provider 配置复制一份文件，再以环境变量传入。不要把含凭据的文件复制进本目录：

```bash
PROBE_PROVIDER_CONFIG=/absolute/path/provider.toml bash probe.sh live.log
```

脚本每次新建临时 `CODEX_HOME`，退出时自动删除，不改用户现有配置。`notify.sh` 只写入该临时目录。依赖 Bash、Node.js、jq 与 Codex CLI。

本次收录的输出只覆盖离线 schema 与严格配置检查，不用于证明模型回答、通知回调或搜索工具已经执行。`history.persistence="none"` 也不等于 `codex exec --ephemeral`，不能用它推断非交互会话不落盘。
