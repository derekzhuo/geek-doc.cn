# flow-yosys-check-command

**对应教程**：https://geek-doc.cn/eda/flow-yosys-check-command.html

Yosys `check` 检查流程的最小复现工程：在一个 4 位 ALU 小设计里故意埋入多驱动与位宽截断两类问题，演示 `check` 在 `proc` 前后放置的差异、`check -assert` 如何当综合前置门禁（非零退出），以及修复后复跑归零。

## 文件

| 文件 | 说明 |
|------|------|
| `alu_bad.v` | 带错设计：`y` 被两个 always 块驱动；`sum` 位宽窄于 `a+b` |
| `alu.v` | 修复版：单一时序驱动块，和拓宽到 5 位 |
| `gate-bad.ys` | 门禁脚本（指向带错设计，演示失败退出码 1） |
| `gate.ys` | 门禁脚本（修复版，退出码 0） |
| `run.sh` | 一条脚本跑完 STEP A–E 完整证据链 |
| `Makefile` | `make run` 在 geek-eda:0.3-sta 容器里执行 |

## 复现

需要本机装有 Docker 并可拉取 `geek-eda:0.3-sta` 镜像（Yosys 0.33）：

```bash
make run
```

或本机原生已装 Yosys 时：

```bash
make native
```

预期：STEP A（check 在 proc 之前）报 0 problems 但属于假清净；STEP B 报 4 条 multiple conflicting drivers；STEP C `check -assert` 以退出码 1 中止；STEP D/E 修复版 `Found and reported 0 problems.`、退出码 0。
