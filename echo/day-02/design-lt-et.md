# Day 2 知识篇：LT vs ET — 两种触发模式的编程范式

> 所属 Day：[Day 2 — epoll/多进程/短连接压测](/demos/echo/day-02/)
> 阅读定位：**知识篇**。本篇回答"LT 和 ET 写起来差在哪、为什么 ET 必须循环读"。
> 更新时间：2026-08-20（重构：从原 Day 2 单篇 128KB 文档拆分）
> 前置阅读：[epoll 非阻塞服务的结构](/demos/echo/day-02/design-io-model.md)
> 深读指引：完整的 LT vs ET 深度对比（事件注册策略、EPOLLOUT 空转陷阱、死锁 Bug 根因）在 [deep-dive](/demos/echo/day-02/deep-dive.md)

---

## 一、本篇要回答的问题

> **LT 和 ET 到底差在哪？为什么 ET 的 accept/read/write 必须循环到 EAGAIN？**

## 二、核心结论速查（一句话版）

| 核心结论 | 详见 |
|---------|------|
| LT 内核帮你追踪 fd 就绪状态，ET 让你自己追踪 | [本质区别](/demos/echo/day-02/deep-dive-lt-et-basics.md#一本质区别谁在追踪fd-是否就绪) |
| ET 下 accept/read/write 必须循环到 EAGAIN，否则数据/连接永久丢失 | [三个关键操作](/demos/echo/day-02/deep-dive-lt-et-basics.md#二三个关键操作的-lt-vs-et-代码对比) |
| LT 手动切事件是"避免噪音"（性能优化），ET 手动切事件是"收到通知"（正确性要求） | [事件注册差异](/demos/echo/day-02/deep-dive-lt-et-register.md) |
| ET 优势在尾延迟（P99 -20%, max -39%），平均 QPS 仅 +6.8% | [性能实测与理论](/demos/echo/day-02/deep-dive-lt-et-perf.md) |
| 三个版本（LT / ET 单进程 / ET 多进程）的递进学习路径 | [递进关系](/demos/echo/day-02/deep-dive-lt-et-perf.md#三三个版本的递进关系) |
| LT 版状态机与事件注册脱节的死锁 Bug 完整分析 | [典型案例](/demos/echo/day-02/deep-dive-lt-et-deadlock.md) |

## 三、EPOLLET 的三个关键循环

EPOLLET 意味着 **"只通知一次状态变化"**——如果这次没处理干净，后续数据来了也不再触发。因此三个操作都必须循环到 EAGAIN：

```c
/* ① accept 循环：多个 SYN 同时到达，一次只取一个 */
while (1) {
    int fd = accept(listen_fd, NULL, NULL);
    if (fd < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK) break;
        perror("accept"); break;
    }
    /* 注册新连接到 epoll ... */
}

/* ② read 循环：边缘触发只通知"有数据来了"，必须自己读到空 */
while (1) {
    ssize_t n = read(fd, buf + buf_len, sizeof(buf) - buf_len);
    if (n > 0) { buf_len += n; continue; }
    if (n == 0) { /* 对端 FIN */ break; }
    if (errno == EAGAIN) break;  /* 读空了 */
    /* 真错误 */
}

/* ③ write 循环：内核发送缓冲区可能写满，部分写后要等 EPOLLOUT */
while (buf_sent < buf_len) {
    ssize_t n = write(fd, buf + buf_sent, buf_len - buf_sent);
    if (n > 0) { buf_sent += n; continue; }
    if (errno == EAGAIN) break;  /* 写满了，等下次 EPOLLOUT */
    /* 真错误 */
}
```

| 操作 | 为什么必须循环 | 退出条件 |
|------|--------------|---------|
| `accept()` | 多个连接同时到达，内核 Accept 队列有多个条目，一次 `accept()` 只取一个 | `errno == EAGAIN` |
| `read()` | 边缘触发只通知"可读了"，收到一批还是多批数据——内核不告诉你，必须读到 EAGAIN | `errno == EAGAIN` 或 `n == 0`（FIN） |
| `write()` | 内核发送缓冲区可能只接受部分数据，剩余数据必须等下次 `EPOLLOUT` 再写 | `errno == EAGAIN` 或全部写完 |

> **EAGAIN 和 EWOULDBLOCK 有区别吗？——在 Linux 上没有。** POSIX 标准允许两者为不同值，但 Linux 将它们定义为同一个 errno（11）：
> ```c
> #define EWOULDBLOCK EAGAIN  // glibc: /usr/include/asm-generic/errno.h
> ```
> 只检查 `EAGAIN` 就完全够了，两者并存是历史兼容写法。

## 四、EPOLLET 的本质代价

| 模式 | 未读空数据时 | 编程复杂度 |
|------|:---|:---|
| LT（水平触发） | 下次 `epoll_wait` **还会通知**，可以下次再读 | 低（不怕漏） |
| ET（边缘触发） | **不再通知**，必须这次循环到 EAGAIN | 高（漏一次丢数据） |

> 省了一次 `epoll_wait` 唤醒，但换来了循环读写的复杂度——这就是 "zero-copy 通知" 换 "复制循环代码" 的权衡。

## 五、结论与回答

### LT vs ET 选型建议（Day 2 实测依据）

| 场景 | 建议 | 依据 |
|------|------|------|
| 短连接、低频 | LT 即可 | 连接太短命，ET 优势没机会发挥 |
| 长连接、高并发、繁忙 | **ET** | 长连接让"重复通知"缺陷现形（见 [Day 3 exp2](/demos/echo/day-03/exp2-lt-vs-et.md)，ET 高 37.2%） |
| 追求尾延迟稳定 | ET | deep-dive 实测 P99 -20%、max -39% |

> **一句话**：LT 是"内核帮你记状态"的省心模式，ET 是"自己记状态"的高性能模式——Day 2 短连接下两者打平，Day 3 长连接下 ET 的优势才显现，这正是本系列"换场景重测"方法论的意义。
