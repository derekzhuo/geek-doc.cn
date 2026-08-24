# Day 23: 全量瓶颈分析 (Full Bottleneck Analysis)

> 所属阶段：阶段 6 — 百万长连接

## 今日目标

在百万连接 + 业务流量的状态下，用 perf + numastat + sar 全量采集数据，做一次完整的瓶颈分析——"当前最大的性能瓶颈到底在哪里？"

## 全量采集命令

```bash
# CPU 微架构
perf stat -e cycles,instructions,branches,branch-misses,\
cache-references,cache-misses,LLC-loads,LLC-load-misses \
-p $(pidof echo-server) sleep 30

# NUMA
numastat -p $(pidof echo-server) > numa_stats.txt

# 网络
sar -n DEV 1 30 > net_stats.txt

# CPU
mpstat -P ALL 1 30 > cpu_stats.txt

# 内存
sar -r 1 30 > mem_stats.txt

# TCP
ss -s > tcp_stats.txt
```

## 分层分析框架

```bash
L1 裸 echo 环境
  ├── QPS 不够？
  │   ├── CPU %usr 高？ → perf top 找热点
  │   ├── %soft 高？ → 软中断不均匀
  │   ├── %iowait 高？ → 磁盘不是瓶颈（echo 无磁盘 I/O）
  │   └── IPC 低？ → 微架构瓶颈（cache miss/分支预测失败）
  ├── 延迟高？
  │   ├── P99 >> P50？ → 尾延迟问题（调度/中断）
  │   ├── 延迟与连接数正相关？ → NUMA 错配
  │   └── 延迟不随连接数变化？ → 网络 RTT 限制
  └── 连接上不去？
      ├── FD 受限？ → ulimit
      ├── 端口耗尽？ → ip_local_port_range
      ├── 内存不足？ → 单连接内存 × 连接数
      └── SYN 积压？ → somaxconn
```

## 当前瓶颈定位

根据收集的数据，判断第一瓶颈属于哪一类，并给出优化建议（可能不需要优化——如果一切正常，这就是最终态）。

## 关键指标记录

| 指标 | 值 | 判断 |
|------|-----|:--:|
| IPC | 待记录 | |
| LLC miss rate | 待记录 | |
| %soft(max) | 待记录 | |
| P99/P50 比值 | 待记录 | |
| numa_miss/s | 待记录 | |

> **一句话总结**：全量瓶颈分析是"体检报告"——不是所有指标都需要优化，但如果 IPC < 0.5 或 numa_miss 持续高位，说明还有提升空间。这一步连接了 L1 echo 的观测和阶段 8 的 L2/L3 进阶。

