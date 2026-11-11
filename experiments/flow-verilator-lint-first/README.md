# flow-verilator-lint-first

**对应教程**：https://geek-doc.cn/eda/flow-verilator-lint-first.html

把 `verilator --lint-only -Wall` 接入一个存量同步 FIFO 工程的最小实验：先对带问题的 RTL 跑出 WIDTHEXPAND 与 UNUSEDSIGNAL 两条告警，修复后复跑到 0 告警。

## 目录

- `rtl_bad/`：接入 lint 前的存量版本（3 位 `count` 隐式扩成 4 位、`dbg` 信号只驱动不消费）
- `rtl_good/`：修复版（显式零扩展 `{1'b0, count}`、删除无用信号，并修正读写计数方向）
- `run.sh` / `Makefile`：复现脚本

## 复现

依赖 docker 镜像 `geek-eda:0.3-sta`（Verilator 5.020）：

```bash
make lint-bad   # 预期 2 条告警、exit_code=1
make lint-good  # 预期无输出、exit_code=0
# 或一把跑完：
bash run.sh
```

本机直装 Verilator 5.x 时，去掉 docker 包装直接执行同名 `verilator` 命令即可。
