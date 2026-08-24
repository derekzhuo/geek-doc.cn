# 阶段 4：发现 CPU 不均衡与软中断（Day 10-12）

> ⏳ **状态：规划中**。

> **撞上的问题**：50K 长连接稳定后，开始给这 50K 连接发送业务流量，发现只有 1 个 CPU 核跑到 100%，其他 7 个核几乎空闲，且 `%soft`（软中断 CPU 占比）极高。

## 背景

连接承载问题基本解决，现在给连接加业务流量——每连接每秒发一条消息。这时候 CPU 的瓶颈暴露了。

## 每日概览

| 天 | 主题 | 关键操作 | 产出 |
|:--:|------|------|------|
| Day 10 | [单 CPU 打满](/demos/echo/day-10/) | 50K 连接 + 每连接 1 msg/s，`mpstat -P ALL` 观测到单核 100%，`sar -n DEV 1` 看 PPS（Packets Per Second，每秒数据包数）分布 | CPU 分布热力图数据 |
| Day 11 | [软中断深入分析](/demos/echo/day-11/) | `/proc/softirqs` 观测 NET_RX 软中断，发现全部集中在一个 CPU | 软中断分布数据 |
| Day 12 | [网卡 RSS 与 IRQ 绑定](/demos/echo/day-12/) | 开启网卡 8 队列 RSS（Receive-Side Scaling，接收端缩放），绑定 IRQ（Interrupt Request，中断请求）到不同 CPU | `scripts/04-nic-tuning.sh` |

## 问题诊断路径

```bash
50K 连接 + 业务流量 → CPU0 100%，其他 7 核空闲
→ mpstat 显示 %soft 占 80%
→ /proc/softirqs 确认 NET_RX 全部在 CPU0
→ /proc/interrupts 确认网卡中断全部路由到 CPU0
→ 开启网卡多队列 RSS → 中断分散到 8 个核
→ CPU 分布均匀，%soft 分摊
```

## 完工验证清单

- [ ] 网卡至少 8 个 RSS 队列
- [ ] 中断均匀分布到 8 个 CPU
- [ ] `mpstat -P ALL` 各核负载均衡（流量场景下）
- [ ] 能解释 RSS 原理和 IRQ 亲和性

> **一句话总结**：连接能承载了但流量上不去——因为你还没发现网卡中断全挤在一个核上，开启 RSS 多队列 + IRQ 绑定才能让 8 个核一起干活。

