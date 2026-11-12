# codex-sandbox-approval-matrix — Codex 沙箱模式与审批策略组合矩阵

**对应教程**：<https://geek-doc.cn/ai-tools/codex/codex-sandbox-approval-matrix.html>（规划篇目，上线后此链接即生效）

把沙箱三模式（只读 / workspace 可写 / full-access）与审批策略逐格组合，用越权写文件和本地 HTTP 探针两类动作实测每一格是放行、拦截还是询问。

## 文件

| 文件 | 作用 |
|---|---|
| `run_matrix.sh` | 矩阵编排：每格起独立临时 `CODEX_HOME` 与工作区，自动回收 |
| `fixture_server.py` | 本地 HTTP 探针服务，记录每个联网请求的路径 |
| `results/` | 逐格真实日志、HTTP 访问记录与汇总 CSV |

## 复现（macOS，需已登录 Codex CLI）

```bash
export CODEX_HOME="$PWD/.tmp-codex-home"   # 指向一个已认证的临时目录
bash run_matrix.sh results
```

脚本不读取、不打印凭据；工作区与探针文件都建在系统临时目录，结束后自动删除。
