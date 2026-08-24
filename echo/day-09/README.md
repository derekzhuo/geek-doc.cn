# Day 9: somaxconn 与 SYN 积压 (somaxconn & SYN Backlog)

> 所属阶段：阶段 3 — TCP 内核参数

## 今日目标

理解 `somaxconn` 和 TCP 三次握手中两个队列的关系，修复高并发建连时的 SYN 积压。

## 前置状态

- FD、端口、缓冲区已调优
- 尚未关注监听队列

## 撞上了什么

```bash
# 突发大规模建连（模拟短连接瞬时高峰）
./echo-client --conn 10000 --mode short --rate 50000

# 观测到
netstat -s | grep -i listen
# 出现 ListenOverflows 和 ListenDrops
# 大量 SYN_RECV 状态堆积
```

## 诊断步骤

```bash
# somaxconn 默认值
cat /proc/sys/net/core/somaxconn
# 128

# 理解两个队列
# SYN Queue（半连接队列）: 收到 SYN 但未完成三次握手的连接
# Accept Queue（全连接队列）: 完成三次握手但尚未被 accept() 取走的连接
# somaxconn 限制的是 Accept Queue 的最大长度

# 查看溢出
netstat -s | grep -E 'LISTEN|overflow'
cat /proc/net/netstat | grep Listen
```

## 修复

```bash
echo 65535 > /proc/sys/net/core/somaxconn

# 同时调整服务端 listen() 的 backlog 参数
# 代码中: listen(fd, 65535)
```

## 原理

```bash
Client                Server
  |---- SYN ---------->|  → 进入 SYN Queue
  |<--- SYN+ACK -------|
  |---- ACK ---------->|  → 进入 Accept Queue（受 somaxconn 限制）
  |                    |  → accept() 从 Accept Queue 取出
```

如果 Accept Queue 满了，新的 ACK 可能被丢弃，客户端需要重传。

## 关键指标记录

| 指标 | 修复前 | 修复后 |
|------|--------|--------|
| `somaxconn` | 128 | 65535 |
| ListenOverflows | > 0 | 0 |
| 突发建连成功率 | 待记录 | 待记录 |

> **一句话总结**：`somaxconn` = 128 在高并发建连场景下就是个笑话——128 个连接的手腕还没热身就被 accept() 取走了不觉得有问题，但瞬时 5 万建连时 Accept Queue 瞬间打满，调高到 65535 才能扛住。

