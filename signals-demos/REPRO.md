---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/signals-demos/`，配套页面 https://geek-doc.cn/demos/signals-demos/


# signals-demos：信号用户态编程五个实验

> 对应文档：[signals-user-demos](/concepts/process/task-resources/signals-user-demos.md)（concepts/process/task-resources/signals-user-demos.md）。本目录代码由该文档内嵌代码同步入库。

## 实验清单

| Demo | 文件 | 核心机制 | 回答的问题 |
|------|------|---------|-----------|
| 1 优雅退出 | `sfd_demo.c` | `signalfd + epoll` | 服务收到 SIGTERM 怎么干净停机？不用 handler、无 async-signal-safe 限制 |
| 2 alarm 超时 | `alarm_demo.c` | `alarm()` + EINTR | `read()` 阻塞太久怎么限时？故意不设 SA_RESTART |
| 3 sigwait 专用线程 | `sigwait_demo.c` | `sigwait` | 主线程专心业务，信号让专人处理？ |
| 4 完整集成 | `sfd_epoll_demo.c` | `signalfd + epoll + SIGHUP 重载` | 生产级主循环 + 优雅停机 + 配置重载骨架 |
| 5 backtrace | `segv_backtrace.c` | `SA_SIGINFO + SA_ONSTACK` | 崩溃时打印调用栈再退出？ |

## 构建与运行

```bash
make all     # 编译全部五个
make run     # 依次运行五个（demo2 需要手动演示超时，demo5 输出崩溃信息）
make run1    # 只跑 demo1
make clean
```

## 要点

- demo1/2/4 是"handler 只做通知、处理放主循环"的直接体现；demo3 用专用线程绕开 handler；demo5 是唯一需要复杂 handler 的场景（崩溃诊断）。
- 每个 demo 开头注释里标注了它在[坑篇](/concepts/process/task-resources/signals-user-pitfalls.md)对应的坑。

## 一句话总结

这五个信号实验演示了信号用户态编程的主流模式：用 signalfd 加 epoll 或 sigwait 专用线程取代复杂 handler，把处理逻辑放回主循环，只有崩溃打印调用栈这类场景才需要 SA_SIGINFO 复杂处理器。
