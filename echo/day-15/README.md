# Day 15: 跨 NUMA 内存访问惩罚 (Cross-NUMA Memory Access Penalty)

> 所属阶段：阶段 5 — 深入 NUMA

## 今日目标

精确量化跨 NUMA 内存访问的性能惩罚，用 `numastat` 和 `perf stat` 从两个维度交叉验证。

## 前置状态

- 已知跨节点绑定性能会恶化
- 尚未量化恶化程度

## 实验：精细化跨 NUMA 内存延迟测量

### 1. 用 numastat 观测

```bash
# server 跑在 Node0，内存分配在 Node1（跨节点错配）
numactl --cpunodebind=0 --membind=1 ./echo-server --port 9090 --workers 4 &
SERVER_PID=$!

# 启动压测
./echo-client --server 127.0.0.1 --port 9090 --conn 10000 --mode long --duration 120 &
CLIENT_PID=$!

# 持续观测 numa_miss
watch -n 1 "numastat -p $SERVER_PID"
```

关键看 `numa_miss` 列——表示进程在 Node0 上运行但访问了 Node1 的内存的次数。跨节点错配下，这个值会非常高。

### 2. 用 perf stat 观测微架构指标

```bash
# 同节点（正确）
numactl --cpunodebind=0 --membind=0 ./echo-server --port 9090 --workers 4 &
perf stat -e cycles,instructions,LLC-loads,LLC-load-misses -p $! sleep 60

# 跨节点（错配）
numactl --cpunodebind=0 --membind=1 ./echo-server --port 9090 --workers 4 &
perf stat -e cycles,instructions,LLC-loads,LLC-load-misses -p $! sleep 60
```

### 对比指标

| 指标 | 同节点 | 跨节点 | 恶化倍数 |
|------|--------|--------|------|
| IPC | 待记录 | 待记录 | |
| LLC-load-misses | 待记录 | 待记录 | |
| P99 延迟 | 待记录 | 待记录 | |
| numa_miss/s | ≈ 0 | 大量 | |

## 原理

跨 NUMA 内存访问时，CPU 需要走 QPI/UPI 总线去远端节点的内存控制器取数据。这比本地内存访问多出：
- 跨总线传输延迟（~2×）
- 远端内存控制器的排队延迟
- 可能的 cache coherency 协议开销（MESIF 需要跨节点通信）

## 关键指标记录

| 指标 | 同节点 | 跨节点 | 恶化 |
|------|--------|--------|------|
| IPC | 待记录 | 待记录 | |
| numa_miss/s | 待记录 | 待记录 | |
| P99 | 待记录 | 待记录 | |

> **一句话总结**：跨 NUMA 内存访问的惩罚不是理论——`numastat` 的 numa_miss 和 `perf stat` 的 LLC miss 会从两个维度告诉你：走远路就是慢，约 1.5-2 倍的延迟惩罚是硬件决定的。
