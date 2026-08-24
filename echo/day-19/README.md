# Day 19: 100K→500K 内存深度分析 (100K→500K Memory Deep Dive)

> 所属阶段：阶段 6 — 百万长连接

## 今日目标

从 100K 推向 500K 连接，重点观测内存变化——精确定量每个连接消耗多少内核内存。

## 前置状态

- 100K 连接稳定，内存使用约 800MB-1GB
- 预估每连接 ~8KB（含 socket、sk_buff、TCP 控制块等）

## 爬升实验

```bash
# 继续从 100K 向 500K 爬升
# 每增加 100K，停留 5 分钟观测

./echo-client --conn 100000 --mode long --duration 300 &
# ... 逐级增加
```

## 内存观测

```bash
# 1. 系统级内存
free -h
cat /proc/meminfo | grep -E '^(MemTotal|MemAvailable|Slab|SReclaimable|SUnreclaim|KernelStack|PageTables)'

# 2. TCP 内存
cat /proc/net/sockstat
# sockets: used 500123
# TCP: inuse 500000 orphan 0 tw 0 alloc 500100 mem 3500000
# mem 单位是 page（4KB）

# 3. Slab 内存（内核对象缓存）
slabtop -o | head -20
# 看 TCP、sock_inode_cache 等对象的 slab 使用量
```

## 精确计算单连接内存

| 内核对象 | 每连接开销 | 说明 |
|------|------|------|
| socket | ~1.2KB | 包括 inode 和 file 结构 |
| sk_buff（收发缓冲） | ~2.3KB | 默认缓冲区大小决定 |
| FD（文件描述符） | ~0.5KB | file 结构 + fdtable |
| 内核栈 | ~0.5KB | 每个连接可能触发内核线程栈分配 |
| 页表 | ~0.5KB | 内存映射的页表开销 |
| TCP 控制块 | ~1.5KB | tcp_sock 结构 |
| **合计** | **~6.5KB** | 100 万 ≈ 6.5GB |

## 验证

```bash
# 500K 连接时
free -h
# used 应该约 4-5GB（含 OS 自身开销）
# 确认 32GB 还剩 25GB+ 可用
```

## 关键指标记录

| 连接数 | 内存 used | slab | TCP mem (page) | FD |
|--------|------|------|------|-----|
| 100K | 待记录 | 待记录 | 待记录 | 待记录 |
| 200K | 待记录 | 待记录 | 待记录 | 待记录 |
| 300K | 待记录 | 待记录 | 待记录 | 待记录 |
| 400K | 待记录 | 待记录 | 待记录 | 待记录 |
| 500K | 待记录 | 待记录 | 待记录 | 待记录 |

> **一句话总结**：32GB 机器上，每连接约 6.5KB 的内核内存开销意味着理论上可以承载 400 万+ 连接——百万连接远不是内存的极限，真正的瓶颈可能是建连速率或 CPU。明天冲击一百万，用数据说话。
