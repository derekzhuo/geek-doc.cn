---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/signal-vs-eventfd/`，配套页面 https://geek-doc.cn/demos/signal-vs-eventfd/

# signal-vs-eventfd — 复现手册

信号通知（`pthread_kill` / `sigwait`）与 `eventfd` 通知的性能与行为对比实验。

## 构建与运行

```bash
make          # 编译 signal_vs_eventfd（gcc -O2 -std=c11 -pthread）
make run      # 运行两种通知方式的对比
make clean    # 清理
```

## 运行要求

Linux（依赖 `eventfd(2)`、POSIX 信号与 pthread）。
