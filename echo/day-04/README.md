# Day 4: 多线程 epoll — 用 thread-per-core 突破单线程天花板

> 所属阶段：阶段 2 — 从单线程到多线程
> 前置依赖：[Day 3 — 短连接 vs 长连接](/demos/echo/day-03/)
> 更新时间：2026-08-20（重构：补充文档地图导航，Day 4 实验按两条线组织——拆机线 + FD 线）
> **核心实验**：[同机基线 v1（= Day 4 完整报告）](/demos/echo/day-04/split-experiment-v1.md)

---

## 一、本 Day 在做什么

Day 3 发现单线程 epoll 服务端在 **500 连接触顶**（[实验 3.3](/demos/echo/day-03/exp3-conn-scale.md)）。Day 4 回答：

> **怎么让服务端拥有并发处理能力？** —— 用 thread-per-core（每核一线程）+ SO_REUSEPORT 多线程化，突破单线程天花板。

Day 4 的实验分**两条线**展开，都从 v1 的同机环境出发，但验证不同瓶颈：

```
                    ┌─────────────────────────────────────────┐
Day 4 同机基线 v1 ──┤ 拆机线：CPU 份额竞争（服务端 vs 压测端） │ → v2 拆机 → v3 升客户端
（4.1~4.4 四实验） ──┤ FD 线：FD 上限（ulimit -n 降档撞墙）   │ → Day 5 FD 机制 → Day 6 10K 验证
                    └─────────────────────────────────────────┘
```

## 二、Day 4 文档地图

### 拆机线（主线，v1 → v2 → v3 逐轮下探）

| 文档 | 回答的问题 | 核心发现 | 轮次定位 |
|------|-----------|---------|---------|
| [split-experiment-v1](/demos/echo/day-04/split-experiment-v1.md) | 多线程能提升多少？同机压测暴露什么瓶颈？ | 4 线程 QPS 提升；暴露"CPU 份额竞争"（服务端 4 线程只抢到 ~2 核） | **基线**（同机 4 核） |
| [split-experiment-v2](/demos/echo/day-04/split-experiment-v2.md) | 拆机后瓶颈消失了吗？ | **4 线程 9.6×**；验证 v1 假说；暴露客户端 8 vCPU 封顶 | v2（32vCPU 服务端 / 8vCPU 客户端） |
| [split-experiment-v3](/demos/echo/day-04/split-experiment-v3.md) | 客户端瓶颈消除后真实上限？ | 253 万 QPS；暴露协议栈瓶颈 + SYN 雪崩（PPS/SYN 队列证据链） | v3（客户端 32 vCPU） |

> **表读法**：三轮是**逐轮下探**——v1 用同机压测暴露"CPU 份额竞争"，v2 拆机后该瓶颈消失、暴露客户端 8 vCPU 封顶，v3 再升级客户端、暴露网络协议栈。每一轮的"角色"列都指向下一轮要验证的问题。

### FD 线（并行支线，产出交给 Day 5/6）

| 文档 | 回答的问题 | 核心发现 | 定位 |
|------|-----------|---------|------|
| [fd-wall-experiment](/demos/echo/day-04/fd-wall-experiment.md) | 主动降档 `ulimit -n` 会发生什么？ | QPS -50%、P999 588ms、EMFILE 刷屏——**FD 墙真实存在** | Day 4 支线 |

## 三、阅读顺序建议

1. **主线必读**：先读 [v1](/demos/echo/day-04/split-experiment-v1.md)（Day 4 完整报告）→ [v2](/demos/echo/day-04/split-experiment-v2.md) → [v3](/demos/echo/day-04/split-experiment-v3.md)
2. **FD 支线选读**：对 FD 上限感兴趣 → [fd-wall-experiment](/demos/echo/day-04/fd-wall-experiment.md) → 接 [Day 5](/demos/echo/day-05/)
3. **深入原理**：thread-per-core + SO_REUSEPORT 的原理见 [Day 2 知识篇](/demos/echo/day-02/design-so-reuseport.md)

> **一句话总结**：Day 4 用 thread-per-core + SO_REUSEPORT 突破单线程天花板——拆机线逐轮下探 CPU 竞争/客户端瓶颈/协议栈瓶颈（v1 同机 → v2 拆机 → v3 升客户端），FD 线并行验证 FD 墙，两条线分别指向 Day 5（FD 机制）与多核扩展的极限。
