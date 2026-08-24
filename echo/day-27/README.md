# Day 27: SYN 队列溢出 (SYN Queue Overflow & ListenOverflows)

> 所属阶段：阶段 7 — 短连接专题

## 今日目标

理解 TCP 三次握手中的 SYN Queue 和 Accept Queue，复现 SYN 队列溢出并修复。

## 两队列回顾

```bash
Client                Server
  |---- SYN ---------->|  → 进入 SYN Queue（半连接队列）
  |                     |    max size: net.ipv4.tcp_max_syn_backlog
  |<--- SYN+ACK -------|
  |---- ACK ---------->|  → 进入 Accept Queue（全连接队列）
  |                     |    max size: min(somaxconn, listen() backlog)
  |               accept() → 从 Accept Queue 取出
```

## 复现 SYN 队列溢出

```bash
# 降低 somaxconn 制造瓶颈
echo 128 > /proc/sys/net/core/somaxconn

# 用 SYN Flood 方式轰服务端
# 或高并发短连接
./echo-client --mode short --rate 100000 --duration 30 &

# 观测
netstat -s | grep -i listen
# 出现：
#   <N> times the listen queue of a socket overflowed
#   <N> SYNs to LISTEN sockets dropped

# 查看实时溢出计数
watch -n 1 'netstat -s | grep -E "overflow|dropped|ListenOverflows|ListenDrops"'
```

## 修复

```bash
# 调大 somaxconn（之前阶段 3 已经调过，这里是专门针对短连接场景验证）
echo 65535 > /proc/sys/net/core/somaxconn

# 调大 SYN backlog
echo 8192 > /proc/sys/net/ipv4/tcp_max_syn_backlog

# 开启 SYN Cookie（SYN 队列满时的兜底机制）
sysctl -w net.ipv4.tcp_syncookies=1
```

## 验证

```bash
# 加大 syn backlog 后重新压测
./echo-client --mode short --rate 100000 --duration 30
netstat -s | grep -i listen
# 不再出现新的溢出
```

## 关键指标记录

| 指标 | 溢出时 | 修复后 |
|------|--------|--------|
| `somaxconn` | 128 | 65535 |
| `tcp_max_syn_backlog` | 默认 | 8192 |
| `tcp_syncookies` | 1 | 1 |
| ListenOverflows | > 0 | 0 |

> **一句话总结**：SYN 队列溢出是短连接场景下的"最后一关"——它发生在三次握手完成之前，比 Accept Queue 满更隐蔽，因为客户端可能只是感觉"建连慢"而不是直接报错。`tcp_max_syn_backlog` 和 `somaxconn` 共同决定了你能扛住多高的瞬时建连速率。

