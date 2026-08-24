# Day 2: epoll/多进程/短连接压测 — 建立性能基线

> 所属阶段：阶段 1 — 从零写出 Echo 服务
> 前置依赖：[Day 1 — 从阻塞模型起步](/demos/echo/day-01/)
> 更新时间：2026-08-20（重构：按"一篇实验 = 一个知识点"拆分，原 128KB 巨型文档拆为导航 + 知识篇 + 实验篇）
> **阶段小结**：[Day 0-2 阶段小结](#九阶段小结day-2-建立基线把快慢变成可测量)

---

## 一、本 Day 在做什么

Day 1 用阻塞模型写出了能跑的 echo 服务（~1K QPS），但"慢在哪里"只有直觉。Day 2 用**三把服务端 + 两把尺子**把"快慢"变成可测量：

| 角色 | 对象 | 说明 |
|------|------|------|
| 服务端 ×3 | `echo-epoll-lt-server.c`（LT） | 水平触发，单进程 |
| | `echo-epoll-server.c`（ET） | 边缘触发，单进程 |
| | `echo-mp-server.c`（ET ×4 worker + SO_REUSEPORT） | 多进程 |
| 压测尺子 ×2 | `echo-bench.c` | 串行、微秒级百分位延迟（量化单连接生命周期） |
| | `bench.sh` | 100 并发 nc（观测高并发 burst 真实行为） |

Day 2 要回答 5 个问题：

| # | 问题 | 答案（一句话） | 出处 |
|---|------|--------------|------|
| Q1 | epoll 比阻塞快多少？ | 10-23×（~1K → 8-14K QPS） | [阶段小结](#九阶段小结day-2-建立基线把快慢变成可测量) |
| Q2 | LT vs ET 谁更快？ | 串行均值 <2% 打平；4 核 LT 反超 13.6%；ET 波动 ±50% vs LT ±15% | [实验：长跑稳态](/demos/echo/day-02/exp-long-run.md) |
| Q3 | 最贵的系统调用是哪个？ | close()（占 21-28%，35-58μs/次） | [实验：syscall 归因](/demos/echo/day-02/exp-syscall.md) |
| Q4 | 长跑为什么失败？ | TIME-WAIT 端口耗尽（累积型，~18%）+ 冷启动（瞬态型） | [实验：失败模式](/demos/echo/day-02/exp-long-run.md) |
| Q5 | MP（多进程）是银弹吗？ | 不是——短跑最优、并发最慢、P999 暴增 7.5×，价值需长连接 + 多核 | [实验：4核对照](/demos/echo/day-02/exp-multi-core.md) |

### 1.1 目录结构

```bash
day-02/
├── README.md
├── Makefile
├── echo-epoll-lt-server.c   # 单进程 epoll LT（水平触发）+ 非阻塞 IO
├── echo-epoll-server.c      # 单进程 epoll EPOLLET（边缘触发）+ 非阻塞 IO
├── echo-mp-server.c         # 多进程 SO_REUSEPORT + 每进程独立 epoll ET
├── echo-bench.c             # 串行压测客户端（测 QPS/延迟百分位）
└── bench.sh                 # 100 并发 nc 压测脚本（测并发容量）
```

四个核心文件的职责划分：

| 文件 | 职责 | 为什么需要 |
|------|------|-----------|
| `echo-epoll-lt-server.c` | 演示 epoll LT（水平触发）的最小可行实现 | **与 ET 版对照**——LT 下可以不循环读，代码更简单但 `epoll_wait` 唤醒次数更多 |
| `echo-epoll-server.c` | 演示 epoll EPOLLET + 非阻塞 I/O 的最小可行实现 | 状态机代码拆分清晰（函数级），适合阅读理解 ET 的强制循环约束 |
| `echo-mp-server.c` | 在 epoll ET 基础上加 fork + SO_REUSEPORT | 状态机逻辑内联在主循环中，展示生产级"一个循环搞定"的紧凑写法 |
| `echo-bench.c` | 精确测量单连接延迟分布的压测工具 | 补充 bench.sh 无法给出的 P50/P99/P999 数据 |

## 二、本 Day 文档地图（按阅读顺序）

### 知识篇（先看懂设计，再跑实验）

| 文档 | 知识点 | 内容 |
|------|--------|------|
| [design-io-model](/demos/echo/day-02/design-io-model.md) | epoll 非阻塞服务的结构 | 整体架构、进程/线程/IO 模型、数据流路径、连接状态机 |
| [design-lt-et](/demos/echo/day-02/design-lt-et.md) | LT vs ET 编程范式 | 两种触发模式的范式对比、EPOLLET 三循环、深读指引 |
| [design-so-reuseport](/demos/echo/day-02/design-so-reuseport.md) | 多进程扩展 | SO_REUSEPORT 多进程架构、worker 分发 |
| [bench-tools](/demos/echo/day-02/bench-tools.md) | 两把压测尺子 | echo-bench（串行延迟）vs bench.sh（并发容量），怎么用才可信 |

### 实验篇（数据 + 归因）

| 文档 | 回答的问题 | 关键数据 |
|------|-----------|---------|
| [exp-short-run](/demos/echo/day-02/exp-short-run.md) | 短跑基线：100 请求串行 | 三架构 8K QPS 打平，瓶颈在测试模型 |
| [exp-long-run](/demos/echo/day-02/exp-long-run.md) | 长跑稳态：10000 请求 + 失败模式 | LT/ET 均值 17.6K/17.4K；Run 3 TIME-WAIT 端口耗尽 17.75% |
| [exp-syscall](/demos/echo/day-02/exp-syscall.md) | 每个系统调用花多少钱 | close() 25% 最贵；13 syscall/req ≈ 110μs |
| [exp-multi-core](/demos/echo/day-02/exp-multi-core.md) | 4核机器全量对照 | 4 核 LT 反超 ET 13.6%；LT-PURE accept 减半 QPS 不变 |
| [analysis-5-layer](/demos/echo/day-02/analysis-5-layer.md) | 五层归因方法论 | L1 总体 → L2 进程 → L3 syscall → L4 根源 → L5 优化 |

## 三、测试矩阵（本 Day 全貌）

| 测试项 | 工具 | 规模 | 覆盖架构 | 数据位置 |
|--------|------|------|---------|---------|
| 短跑基线 | echo-bench | 100 req 串行 | LT/ET/MP | exp-short-run |
| 长跑稳态 | echo-bench | 10000 req 串行 | LT/ET | exp-long-run |
| 并发容量 | bench.sh | 100 并发 nc | LT/ET/MP | exp-short-run |
| syscall 归因 | strace -c | 100 / 10000 req | LT/ET/MP/LT-PURE | exp-syscall |
| 失败模式 | echo-bench 连跑 | 多轮 | LT/ET | exp-long-run |
| 4核对照 | run_all_comprehensive.sh | 12 项全量 | 4 架构 | exp-multi-core |

## 四、编译与运行

**前置状态**（阅读/复现前需满足）：
- [day-01](/demos/echo/day-01/) 的 `server.c` 和 `client.c` 已跑通
- 仍是单进程阻塞模型
- 已理解 `socket()` → `bind()` → `listen()` → `accept()` 的内核行为（[day-01 deep-dive](/demos/echo/day-01/deep-dive.md)）

```bash
# 前置：ulimit（< 10000 时执行）
ulimit -n 65535

# 编译三个服务端 + 两个工具
cd demos/echo/day-02 && make all

# 终端 1：启动任一服务端（LT / ET / MP）
make run-lt    # 或 run-et / run-mp

# 终端 2：压测
make run-bench-lt   # echo-bench 串行 100 req（短跑）
make run-bench-et
make run-bench-mp

# 长跑（10000 req）
echo-bench 127.0.0.1 9988 100 100
```

## 五、五个核心结论（本 Day 答案速览）

| # | 结论 | 证据 | 指向下一站 |
|---|------|------|-----------|
| 1 | QPS 由内核路径决定：短跑 8K → 长跑稳态 17.6K | 13 syscall/req ≈ 110-150μs，TCP 握手吃 30-50% | Day 3 长连接（消 connect/close） |
| 2 | 串行场景 LT≈ET（均值 <2%），差异在波动性 | ET ±50% vs LT ±15%，ET 优势在尾延迟 | Day 3 长连接才见 ET 真优势 |
| 3 | MP 依赖负载，非银弹 | 短跑最优 / 并发最慢 / P999 7.5× | SO_REUSEPORT 需长连接 + 多核 |
| 4 | 失败分两种，根因均与 LT/ET 无关 | 累积型 = TIME-WAIT 端口耗尽；瞬态型 = 调度抖动 | 测试方法学问题 |
| 5 | close() 是最贵 syscall（21-28%） | strace 35-58μs/次 | **Day 3 直接动因** |

---

## 九、阶段小结：Day 2 建立基线，把"快慢"变成可测量

> 更新时间：2026-08-17（原文保留）

Day 2 是第一个"量化"实验——用三个服务端（LT/ET/MP）和两把尺子（`echo-bench` 串行延迟、`bench.sh` 并发容量）把 Day 1 的"直觉慢"变成精确数字，并用**五层归因（L1 总体 → L5 优化）**把"为什么有这个数字"讲透。

### 9.1 本 Day 做了什么

| 产出 | 说明 |
|------|------|
| 三个服务端 | `echo-epoll-lt-server`（LT）/ `echo-epoll-server`（ET）/ `echo-mp-server`（ET×4 worker + SO_REUSEPORT）|
| 两个压测工具 | `echo-bench.c`（串行、微秒级百分位）/ `bench.sh`（100 并发 nc）|
| 两轮数据 | 20 核机器 + 4 核机器全量对照（2026-07-29）|
| 五层归因框架 | L1 总体 → L2 进程 → L3 syscall → L4 根源 → L5 优化 |

> 本 Day 最大的方法论贡献是**双机对照 + 五层归因**：20 核机器证明"LT/ET 均值打平"，4 核机器证明"低核数下 LT 反超 ET 13.6%"——单机数据永远无法剥离"核数相关"与"核数无关"的结论，双机对照才把"核数"从变量中独立出来。

### 9.2 核心结论

| 结论 | 证据 | 对后续的意义 |
|------|------|------|
| epoll 比阻塞快 10-23 倍 | Day 1 ~1K → Day 2 短跑 8-14K | 事件驱动是第一个数量级提升 |
| 串行场景 LT≈ET（均值 <2%），4 核 LT 反超 13.6% | 长跑数据 / 4核对照 | LT/ET 选型取决于核数与负载 |
| close() 是最贵 syscall（21-28%） | strace 实测 35-58μs/次 | 直接指向 Day 3 长连接 |
| 长跑 ~18% 失败 = TIME-WAIT 端口耗尽 | Run 3 累积 28225 逼近 28231 | 测试方法学问题，非代码 bug |
| MP 依赖负载，非银弹 | 短跑最优 / 并发最慢 / P999 暴增 7.5× | SO_REUSEPORT 需长连接 + 多核才发挥 |

> 五条结论的共性：**Day 2 找到的每个瓶颈都标注了下一站**——close() 最贵 → Day 3 长连接；单核上限 → Day 4 多线程；MP 负载依赖 → 长连接 + 多核场景；TIME-WAIT 端口耗尽 → 内核参数治理。这正是"逐层归因 → 逐层拆除"实验方法论的体现。

### 9.3 承上启下：Day 2 的发现 → 后续 Day 的验证

| Day 2 的发现 | 后续验证 | 结果 |
|------|------|------|
| close() 消除后 QPS 应提升 2-5× | [Day 3 长连接](/demos/echo/day-03/) | ET 2.15× ✅（LT 1.48×，暴露新瓶颈）|
| 单线程 epoll 有吞吐天花板 | [Day 4 多线程](/demos/echo/day-04/split-experiment-v1.md) | 拆机后 4 线程 9.6× ✅ |
| LT 重复通知在长连接下放大 | Day 3 / 拆机 v2/v3 | 长连接 ET 高 37.2%；CPU 充裕时差距坍缩 <10% |

> 承上启下的关键是看清"每轮结论的保质期"：Day 2 的 LT≈ET、MP 非银弹都是**特定负载与核数下的结论**，换成长连接（Day 3）、换成多线程（Day 4）后全部被改写——这就是为什么本系列坚持每个 Day 都要重测、而不是沿用上一轮结论。

### 9.4 后续实验规划（Day 3+）

> 原文 §8.9 保留。状态：✅ 已完成 / 🔶 部分完成 / 🔜 计划。

**Day 3+ 计划实验**：

| 阶段 | 实验 | 预期价值 | 与 Day 2 的衔接 |
|------|------|---------|----------------|
| **Day 3** | **长连接 Keep-Alive** | QPS 数倍提升（close 占 18-26%） | 消除短连接固定税后看到 ET/LT/MP 真实差异 |
| **Day 3** | **C10K 长连接压测** | ET "减少重复通知"优势在此放大 | Day 2 330 并发未触及，是 ET 优势的真正试金石 |
| **Day 3** | **远程网络测试** | 暴露 localhost 看不到的网卡/协议栈瓶颈 | 当前数据全为 localhost |
| **Day 4** | **NUMA 拆分** | 消除 MP P999 暴增的调度抖动 | 直接针对"MP 非银弹"结论 |
| **Day 4** | **io_uring/zero-copy** | 绕过 epoll 多次 syscall | 验证数据拷贝 10-15% 是否为进一步优化空间 |
| **Day 5** | **容器化性能** | 量化容器网络栈额外延迟 | 生产部署前必测 |
| **Day 5** | **TCP 拥塞控制/缓冲区调优** | tcp_tw_reuse 等对 TIME-WAIT 的影响 | 直接针对累积型失败 |

**待解谜题**（原文 §8.9.3，已闭环 3 项）：
1. ~~LT ET 省 60% CPU 但 epoll_wait 只解释 30%~~ ✅ 已闭环：ET 每个 syscall 快 7-17%，累积为 10% 总时间优势
2. **LT 并行 epoll_wait 12 μs 离群点**（比 ET 早 50% 出现）— 4 核机器上未复现，可能与 20 核机器的调度器行为差异有关，需更高核数验证
3. ~~**LT 纯范式 vs 当前实现**~~ ✅ 已闭环：accept 调用减半但 QPS 无显著提升（省错误 ≠ 省时间）
4. **MP "负载依赖"拐点** — 需 100/500/1000/5000 req 扫描定位（4 核机器仅完成 100/10000）
5. **ET QPS 波动 ±50% 根因** — CPU 缓存热态 vs 循环深度随机？
6. ~~**并行下 LT/ET syscall 级别完整对比**~~ ✅ 已闭环：并行下 QPS 差距在 ±10% 以内，epoll 差异被短连接固定税稀释

> **一句话总结**：Day 2 的终点是"知道了慢在哪"（close()、单核、TIME-WAIT），Day 3 起开始逐一拆除——但每拆一个瓶颈就会暴露下一层，这正是 Day 3 / Day 4 与拆机系列 v1/v2/v3 的故事主线。
