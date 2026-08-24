# Day 11: 软中断深入分析 (Softirq Deep Dive — NET_RX)

> 所属阶段：阶段 4 — CPU 与软中断

## 今日目标

深入理解软中断（Softirq）机制——它是什么、为什么它能让 CPU0 跑到 80%，以及怎么观测。

## 什么是软中断

硬件中断（Hard IRQ）处理时间必须极短（微秒级），否则会阻塞其他中断。耗时的网络协议栈处理（TCP/IP 解析、socket 唤醒）被推迟到**软中断**（Softirq）上下文执行。

```bash
网卡收包流程:
  硬件中断 → NAPI poll → 软中断 NET_RX → 内核协议栈 → socket 就绪 → epoll 唤醒
```

## 要做什么

### 1. 用 mpstat 观测 %soft

```bash
mpstat -P ALL 1
# %soft 列 = 软中断占用的 CPU 比例
```

### 2. 用 /proc/softirqs 确认类型

```bash
watch -n 1 'cat /proc/softirqs'
```

输出示例（截取关键行）：
```bash
          CPU0       CPU1     ...      CPU7
NET_RX: 58392013  0             0      0     ← 全部在 CPU0！
NET_TX: 1203847   15            8      12    ← 发送也偏斜
```

### 3. 用 /proc/interrupts 向上溯源

```bash
cat /proc/interrupts | grep -E 'CPU0|eth0'
# 网卡的中断计数全部在 CPU0
```

## 关键概念

| 概念 | 含义 | 观测方式 |
|------|------|------|
| %soft | 软中断 CPU 占比 | `mpstat -P ALL` |
| NET_RX | 收包软中断 | `/proc/softirqs` |
| NET_TX | 发包软中断 | `/proc/softirqs` |
| IRQ affinity | 硬中断 CPU 亲和 | `/proc/irq/<N>/smp_affinity` |

## 问题定位结论

```bash
高流量 → 网卡频繁硬中断 → CPU0（IRQ 默认亲和） → 大量软中断 NET_RX → CPU0 %soft = 80%
→ 其他 7 个核闲置
```

## 关键指标记录

| 指标 | CPU0 | CPU1-7 |
|------|------|--------|
| %soft | ~80% | ~1% |
| NET_RX/秒 | 数百万 | ~0 |

> **一句话总结**：%soft 飙高不是 CPU 不够用，而是中断全部默认路由到一个核——硬件中断→软中断→协议栈这个链条全部锁死在 CPU0，理解清楚这个机制后，明天用 RSS 多队列来分流。

