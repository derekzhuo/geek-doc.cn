# Day 13: 发现 NUMA 拓扑 (Discover NUMA Topology)

> 所属阶段：阶段 5 — 深入 NUMA

## 今日目标

RSS + IRQ 优化后 8 核都用上了，但一个微妙的现象逐渐浮现：同一台机器上两个核组的延迟不一致。今天用 `lscpu` 和 `numactl` 来揭示 NUMA 拓扑。

## 撞上了什么

```bash
# 长期运行后，sar 数据显示:
# CPU 0-3 所在服务的 P99 延迟 比 CPU 4-7 稳定 ~30%
# 两者的 QPS 也有差异

# 这不应该——RSS 已经把中断均衡了
```

## 诊断步骤

### 1. 查看 CPU 拓扑

```bash
lscpu
```

关键输出：
```bash
Architecture:        x86_64
CPU(s):              8
Thread(s) per core:  1
Core(s) per socket:  4
Socket(s):           2
NUMA node(s):        2       ← 两个 NUMA 节点！
NUMA node0 CPU(s):   0-3     ← Node0: CPU 0-3
NUMA node1 CPU(s):   4-7     ← Node1: CPU 4-7
```

### 2. 用 numactl 查看详细信息

```bash
numactl --hardware
```

输出：
```bash
available: 2 nodes (0-1)
node 0 cpus: 0 1 2 3
node 0 size: 16384 MB       ← Node0 的本地内存
node 0 free: 10240 MB
node 1 cpus: 4 5 6 7
node 1 size: 16384 MB       ← Node1 的本地内存
node 1 free: 11234 MB
node distances:
node   0   1
  0:  10  21               ← 跨节点访问延迟是本地 2.1 倍
  1:  21  10
```

### 3. 理解 NUMA 对性能的影响

```bash
┌─────────────────────┐   ┌─────────────────────┐
│    NUMA Node 0      │   │    NUMA Node 1      │
│  CPU 0-3            │   │  CPU 4-7            │
│  本地内存 16GB       │   │  本地内存 16GB       │
│  访问本地: 快        │   │  访问本地: 快        │
│  访问 Node1: 慢 2×  │   │  访问 Node0: 慢 2×  │
└─────────────────────┘   └─────────────────────┘
         ↑─── UPI/QPI 总线 ────↑
```

## 为什么之前的优化没发现这个问题

- FD/TCP 瓶颈是全局的，不受 NUMA 影响
- RSS 把中断均衡到 8 个核，但没有区分 NUMA 节点
- 当进程跑在 Node0 但访问 Node1 的内存 → 跨 NUMA 延迟惩罚 → 这就是为什么 CPU0-3 和 CPU4-7 表现不一致

## 关键指标记录

| 指标 | 值 |
|------|-----|
| NUMA 节点数 | 2 |
| 每节点核数 | 4 |
| 每节点内存 | 16GB |
| 跨节点延迟倍数 | 2.1× |

> **一句话总结**：NUMA 是你用尽了"单机均匀资源"模型后才发现的深层架构——8 核不是 8 核，是 2×4 核，内存也不是一个 32GB 大池子，而是两个 16GB 的小池子。跨节点访问要付出 2 倍延迟的代价。

