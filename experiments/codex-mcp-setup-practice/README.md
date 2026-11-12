# Codex filesystem MCP 最小复现

**对应教程**：https://geek-doc.cn/ai-tools/codex/codex-mcp-setup-practice.html（上线后生效）

这是一个零 npm 依赖的标准 stdio MCP filesystem server，以及 Codex CLI 正常调用与三个故障的复现脚本。

## 文件

- `server.mjs`：实现 `initialize`、`tools/list`、`tools/call`，提供 `read_text_file` 与 `list_allowed_directories`。
- `run.sh`：在 `/tmp` 建立隔离工作区与 `CODEX_HOME`，依次运行正常读取、越界路径、server 文件缺失、stdout 污染四组案例。
- `output/`：真实运行的合并 stdout/stderr 记录。

## 复现

需要已安装并登录 Codex CLI。脚本只把现有登录文件复制到临时 `CODEX_HOME`，不会修改真实配置，也不会把认证内容写进输出。

```bash
WORK_DIR=/tmp/codex-mcp-setup-practice OUT_DIR="$PWD/output" bash run.sh
```

越界路径通过 MCP 的 `isError` 结果返回，另外两类启动故障会出现在 Codex 的 JSONL 事件与 stderr 中。脚本末尾的 `*_case_exit=0` 只表示 Codex 会话自身正常结束，不等于工具调用成功；应以 MCP 调用结果判断。
