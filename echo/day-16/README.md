# Day 16: 双 NUMA 多进程拆分 (Dual-NUMA Multi-Process Split)

> 所属阶段：阶段 5 — 深入 NUMA

## 今日目标

最终方案：不把全部 worker 压在单个 NUMA 节点上，而是**双 NUMA 拆分**——每个 NUMA 节点跑 4 个 worker，各自绑定到本地 CPU 和本地内存。

## 最优配置

```bash
NUMA Node0（CPU 0-3, 内存 16GB）
├── worker 1 → CPU 0, 本地内存
├── worker 2 → CPU 1, 本地内存
├── worker 3 → CPU 2, 本地内存
└── worker 4 → CPU 3, 本地内存
    + IRQ 0-3（对应 Node0 的网卡中断）

NUMA Node1（CPU 4-7, 内存 16GB）
├── worker 5 → CPU 4, 本地内存
├── worker 6 → CPU 5, 本地内存
├── worker 7 → CPU 6, 本地内存
└── worker 8 → CPU 7, 本地内存
    + IRQ 4-7（对应 Node1 的网卡中断）
```

## 启动命令

```bash
# 用脚本一键启动
bash scripts/numa-split-server.sh --port 9090 --workers-per-node 4
```

脚本逻辑：
1. 检测 NUMA 拓扑（节点数、每节点 CPU 数）
2. 在每个 NUMA 节点上 fork 对应数量的 worker
3. 每个 worker 用 `numactl --cpunodebind= --membind=` 绑定
4. 网卡 IRQ 按 NUMA 节点对齐

## 对比测试

```bash
# 单 NUMA 8 进程（旧的错误方式）
./echo-server --port 9090 --workers 8 &
./echo-client --conn 50000 --mode long --duration 60

# 双 NUMA 各 4 进程（新的正确方式）
bash scripts/numa-split-server.sh --port 9090 --workers-per-node 4
./echo-client --conn 50000 --mode long --duration 60
```

## 预期结果

| 配置 | QPS | P99 | numa_miss |
|------|-----|-----|-----------|
| 单 NUMA 8 进程 | 基线 | 基线 | 部分跨节点 |
| 双 NUMA 各 4 进程 | ▲▲ 接近 2× | ▼▼ | ≈ 0 |

实际应接近 2 倍提升——因为之前一半的 worker 在跨 NUMA 糟糕地运行。

## 关键产出

- `scripts/numa-bind-server.sh`：单 NUMA 绑核启动
- `scripts/numa-split-server.sh`：双 NUMA 拆分启动
- `scripts/numa-benchmark.sh`：自动跑分（4 场景 × 3 轮中位数）
- `scripts/numa-check.sh`：NUMA 状态一键检查

## 关键指标记录

| 指标 | 单 NUMA 8 进程 | 双 NUMA 拆分 | 提升 |
|------|------|------|------|
| QPS | 待记录 | 待记录 | |
| P99 | 待记录 | 待记录 | |
| numa_miss/s | 待记录 | ≈ 0 | |

> **一句话总结**：双 NUMA 拆分是 NUMA 优化的终局——进程、内存、网卡中断三者必须在同一个 NUMA 节点内（"就近原则"），拆分后的 QPS 接近翻倍是"物理定律"决定的，不是魔法。

