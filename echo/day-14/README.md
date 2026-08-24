# Day 14: 进程 CPU 绑定实验 (Process CPU Binding Experiments)

> 所属阶段：阶段 5 — 深入 NUMA

## 今日目标

用 `taskset` 和 `numactl` 做进程 CPU 绑定实验，对比"不绑核"、"同 NUMA 绑核"、"跨 NUMA 绑核"三种模式的性能差异。

## 实验设计

| 实验 | 配置 | 问题 |
|------|------|------|
| 基线 | 不绑核，Linux 调度器自由调度 | CPU 迁移影响 cache |
| 同节点绑核 | `taskset -c 0-3` + 内存也在 Node0 | 预期性能最佳 |
| 跨节点绑核 | 进程跑在 Node0，但内存分配在 Node1 | 预期延迟恶化 |

## 实验步骤

### 实验 1: 基线（不绑核）

```bash
./echo-server --port 9090 --workers 4 &
./echo-client --server 127.0.0.1 --port 9090 --conn 10000 --mode long --duration 60
```

### 实验 2: 同 NUMA 节点绑核

```bash
# 把 server 所有 worker 绑在 Node0
numactl --cpunodebind=0 --membind=0 ./echo-server --port 9090 --workers 4 &
./echo-client --server 127.0.0.1 --port 9090 --conn 10000 --mode long --duration 60
```

### 实验 3: 跨 NUMA 节点（错配）

```bash
# 进程跑在 Node0，但内存分配在 Node1
numactl --cpunodebind=0 --membind=1 ./echo-server --port 9090 --workers 4 &
./echo-client --server 127.0.0.1 --port 9090 --conn 10000 --mode long --duration 60
```

## 观测指标

```bash
# CPU 分布
mpstat -P ALL 1

# NUMA 状态
numastat -p $(pidof echo-server)

# 延迟
# 记录客户端 P50/P99
```

## 预期结果

| 实验 | QPS | P99 延迟 | numa_miss/s |
|------|-----|------|-------------|
| 不绑核 | 基线 | 基线 | 少量 |
| 同节点 | ▲ 高于基线 | ▼ 低于基线 | ≈ 0 |
| 跨节点 | ▼ 明显低于基线 | ▲ 显著高于基线 | 大量 |

## 关键指标记录

| 实验 | QPS | P99 | numa_miss | 结论 |
|------|-----|-----|-----------|------|
| 基线 | 待记录 | 待记录 | 待记录 | |
| 同节点 | 待记录 | 待记录 | 待记录 | |
| 跨节点 | 待记录 | 待记录 | 待记录 | |

> **一句话总结**：三种模式的实际数据最能说明问题——同节点绑核是最优的，跨节点错配是最差的，不绑核处于中间。这个实验让你亲眼看到 NUMA 带来的性能差异，而不只是纸面上的理论。
