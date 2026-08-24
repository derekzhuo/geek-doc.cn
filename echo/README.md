# 百万 QPS TCP Echo 系统 — 从零到百万连接

> **不预设优化，不提前调参。** 先写出能跑的 TCP Echo 服务，再在压测中逐个撞上瓶颈，每个瓶颈都是一次诊断—定位—修复的完整闭环。

> **当前进度**：✅ 阶段 1/2 已完成（Day 1-6），阶段 3-8 规划中。总览见 [项目总纲](/demos/echo/docs/00-overview.md)。

## 架构总览

| 层级 | 服务 | 用途 | 覆盖维度 |
|------|------|------|----------|
| **L1** | 裸 echo | 收发原样返回，零业务干扰 | FD 上限、连接承载、内核协议栈 |
| **L2** | 带计算 echo | 收发 + 可调 CPU 运算权重 | perf 微架构分析、CPU/网络混合瓶颈 |
| **L3** | 流式分包 echo | 帧协议拆包 + 粘包处理 | TCP 流式语义、缓冲区管理 |

> 层级正交独立，可单独实验。详细设计见 [架构设计文档](/demos/echo/docs/architecture.md)。

## 学习路线（8 阶段 × 30 天）

| 阶段 | 天数 | 撞上的问题 | 状态 | 详情 |
|------|:--:|------|:--:|------|
| 1. 写出 Echo | Day 1-3 | TCP socket 编程，从 localhost 到云主机 | ✅ | [→](/demos/echo/docs/01-phase1-from-scratch.md) · [小结](/demos/echo/docs/01b-phase1-summary.md) |
| 2. 多线程扩展与 FD 上限 | Day 4-6 | 单线程 epoll 触顶 → 多线程扩展；主动降档实测撞 FD 墙 | ✅ | [→](/demos/echo/docs/02-phase2-fd-bottleneck.md) · [小结](/demos/echo/docs/02b-phase2-summary.md) |
| 3. TCP 参数 | Day 7-9 | 建连超时、端口不够、缓冲区不足 | ⏳ | [→](/demos/echo/docs/03-phase3-tcp-kernel.md) |
| 4. CPU/软中断 | Day 10-12 | 流量上来后单 CPU 打满 | ⏳ | [→](/demos/echo/docs/04-phase4-cpu-softirq.md) |
| 5. NUMA 深入 | Day 13-16 | CPU 分布不均衡 → 发现 NUMA | ⏳ | [→](/demos/echo/docs/05-phase5-numa-deep.md) |
| 6. 百万连接 | Day 17-23 | 20→50→100→500→1000K 逐级爬升 | ⏳ | [→](/demos/echo/docs/06-phase6-million-conn.md) |
| 7. 短连接 | Day 24-27 | TIME_WAIT 爆炸、端口耗尽 | ⏳ | [→](/demos/echo/docs/07-phase7-short-conn.md) |
| 8. 进阶复盘 | Day 28-30 | L2/L3 echo + 全链路闭环 | ⏳ | [→](/demos/echo/docs/08-phase8-advanced-review.md) |

> 每日执行详情见 [Day 1: TCP Echo 从零](/demos/echo/day-01/)，后续每日文档在各 `day-NN/README.md` 中。

## 快速开始

```bash
# 阶段 1 开始：一台干净的 CentOS Stream 9 云主机，只安装了 gcc/make
cd /opt/echo/src && make all

# L1 裸 echo 验证
./bin/echo-server --port 9090 --workers 1 &
./bin/echo-client --server 127.0.0.1 --port 9090 --conn 10 --mode long
```

## 关键文档

**总览与路线**

| 文档 | 内容 |
|------|------|
| [项目总纲](/demos/echo/docs/00-overview.md) | 学习目标、硬件环境、8 阶段路线、问题驱动理念 |
| [架构设计](/demos/echo/docs/architecture.md) | 三层代码架构蓝图（L1/L2/L3）、组件图、内存模型、时序图 |
| [分析指南](/demos/echo/docs/analysis.md) | 分层定位法、5 大场景排查、命令速查 |
| [阶段 1 小结](/demos/echo/docs/01b-phase1-summary.md) | Day 0-3 复盘：瓶颈接力、QPS ~1K→53.5K、方法论沉淀 |
| [阶段 2 小结](/demos/echo/docs/02b-phase2-summary.md) | Day 4-6 复盘：三条主线结论、交付物地图、下一步方向 |

**阶段 1：写出 Echo（Day 1-3，✅ 已完成）**

| 文档 | 内容 |
|------|------|
| [Day 1 代码](/demos/echo/day-01/) | 起步代码、编译步骤、迭代计划 |
| [Day 1 深入原理](/demos/echo/day-01/deep-dive.md) | 4 篇独立原理：系统调用 / sk_buff / MSS-Nagle-cwnd / read() 语义 |
| [Day 2 基线](/demos/echo/day-02/) | 知识篇（架构/LT vs ET/SO_REUSEPORT/压测工具）+ 实验篇（短跑/长跑/syscall/4核对照/五层归因） |
| [Day 3 长连接](/demos/echo/day-03/) | 5 篇小实验：QPS 对比 / LT vs ET / 连接数扫描 / strace 实证 / 跨网络 |

**阶段 2：多线程扩展与 FD 上限（Day 4-6，✅ 已完成）**

| 文档 | 内容 |
|------|------|
| [Day 4 多线程 epoll](/demos/echo/day-04/) | 拆机线 v1→v2→v3（见下）+ FD 线：[FD 墙实测](/demos/echo/day-04/fd-wall-experiment.md) 降档撞墙（QPS -50%、P999 588ms） |
| ├ [拆机 v1 同机基线](/demos/echo/day-04/split-experiment-v1.md) | 线程数扩展、多线程下 LT vs ET、连接数扫描 |
| ├ [拆机 v2 拆机](/demos/echo/day-04/split-experiment-v2.md) | 8 vCPU 客户端 → 69 万连接 |
| └ [拆机 v3](/demos/echo/day-04/split-experiment-v3.md) | 32 vCPU → 253 万，协议栈瓶颈 |
| [Day 5 FD 机制](/demos/echo/day-05/) | FD 三层限制模型、[机制实测](/demos/echo/day-05/fd-mechanism-experiment.md)、[持续空转实测](/demos/echo/day-05/sustained-spin-experiment.md)、[四层链诊断](/demos/echo/day-05/ulimit-chain-experiment.md) |
| [Day 6 万连接验证](/demos/echo/day-06/) | 10K 长连接稳定验证、阶段性成果固化 |

> 每日执行详情见 [Day 1: TCP Echo 从零](/demos/echo/day-01/)，后续每日文档在各 `day-NN/README.md` 中。

> **一句话总结**：8 阶段 × 30 天问题驱动——先撞墙再找路，从 TCP socket 编程到百万长连接全链路闭环，每个优化都有根有据。
