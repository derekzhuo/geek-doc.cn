# 深入论述三：MSS/MTU、Nagle 算法、cwnd 拥塞窗口（索引）

> 所属 Day：[Day 1 从零编码](/demos/echo/day-01/) · 更新时间：2026-08-21（重构：从原 deep-dive.md 拆分，本文成为索引）
> 上一篇：[深入论述二：sk_buff 的设计与组织](/demos/echo/day-01/theory-sk-buff.md)
> 下一篇：[1/6 MSS 与 MTU](/demos/echo/day-01/theory-mss-mtu.md)

这三个概念在"网络传输层面"已初步提及，但它们对 TCP 性能的影响远比表面看起来复杂——特别是**三者之间的相互作用**，是理解 TCP 延迟和吞吐量的关键。

**术语速查**：

| 缩写 | 全称 | 一句话定义 | 在哪层生效 |
|------|------|-----------|-----------|
| **MTU** | Maximum Transmission Unit | 链路层单帧最大载荷（以太网默认 1500 字节） | L2 链路层 |
| **MSS** | Maximum Segment Size | TCP 单段最大载荷，`MSS = MTU - 40`（IP头20 + TCP头20），三次握手协商 | L4 TCP 层 |
| **PMTUD** | Path MTU Discovery | 通过 ICMP "Frag Needed" 发现路径上最小 MTU | L3 IP 层 |
| **Nagle** | Nagle 算法 (RFC 896) | 合并小 `write()`：任一时刻最多一个未确认小段 | L4 TCP 层 |
| **cwnd** | Congestion Window | 发送端维护的拥塞窗口，限制在途数据量 | L4 TCP 发送端 |
| **rwnd** | Receive Window | 接收端通告的接收窗口，`read()` 慢 → rwnd 小 | L4 TCP 接收端 |
| **ssthresh** | Slow Start Threshold | 慢启动阈值，cwnd 超过它后进入拥塞避免 | L4 TCP 发送端 |
| **RTT** | Round Trip Time | 数据从发送到收到 ACK 的往返时间 | 贯穿 L2-L4 |
| **BDP** | Bandwidth-Delay Product | 带宽×延迟积，理论上能填满管道的在途数据量 | 端到端 |

> **核心关系**：`MSS` 决定每段大小 → `Nagle` 决定何时合并小段 → `cwnd` 决定能发多少段 → 实际吞吐量 = `min(cwnd, rwnd) / RTT`。四个参数像串行的阀门，任何一个关小了，整条连接就被限速。

> **本文已拆分为 6 篇子文档**，每篇一个主题，建议按顺序阅读：

| 顺序 | 子文档 | 内容 | 篇幅 |
|:--:|------|------|:--:|
| 1 | [MSS 与 MTU](/demos/echo/day-01/theory-mss-mtu.md) | 握手协商、六个决定因素、IP 分片 vs TCP 分段 | ★ |
| 2 | [Nagle 算法](/demos/echo/day-01/theory-nagle.md) | 合并小包、Delayed ACK 死锁交互、适用性判断 | ★ |
| 3 | [双窗口递进序列图](/demos/echo/day-01/theory-cwnd-rwnd-sequences.md) | 六轮 RTT 中 cwnd/rwnd 的权力交接、慢启动的"慢"、rwnd 崩溃 | ★★★ |
| 4 | [两种窗口本质区别与 rwnd 生成](/demos/echo/day-01/theory-cwnd-rwnd-details.md) | 自律 vs 通告、rwnd 计算路径、零窗口探针 | ★★ |
| 5 | [cwnd 四阶段与拥塞控制算法](/demos/echo/day-01/theory-congestion-control.md) | 慢启动/拥塞避免/快速恢复/超时、CUBIC vs BBR、三层选型 | ★★★ |
| 6 | [协同场景与工程速查](/demos/echo/day-01/theory-window-engineering.md) | 四种场景、read() 拿不全数据的四层根源、调参警告 | ★★ |

> 阅读建议：先读 1-2（分段与合并）理解"数据怎么被拆装"，再读 3-4（双窗口模型）理解"数据怎么被限速"，最后读 5-6（阶段/算法/调参）获得工程视角。

> **一句话总结**：MSS 定段大小、Nagle 管小包合并、cwnd/rwnd 双窗口限在途量——实际吞吐 = min(cwnd, rwnd) / RTT，四个阀门任何一个关小整条连接就被限速；`read()` 一次拿不到全部数据，就是这四个阀门联合作用的结果。
