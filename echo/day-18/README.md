# Day 18: keepalive 与死连接回收 (Keepalive & Dead Connection Detection)

> 所属阶段：阶段 6 — 百万长连接

## 今日目标

10 万连接稳定后，模拟一个真实场景：部分客户端断网了但没发 FIN，服务端怎么知道并回收这些"死连接"？

## 模拟死连接

```bash
# 建立 10 万连接
./echo-client --conn 100000 --mode long --duration 99999 &

# 等待建连完成后，kill -9 客户端进程
# 此时服务端以为连接还在（TCP 层面没有收到 FIN/RST）
ss -tan | grep ESTAB | wc -l
# 仍然显示有这些连接
```

## 问题

默认 `tcp_keepalive_time = 7200`（2 小时）——意味着死连接要 2 小时后才被回收。在高并发场景下，2 小时内可能积累大量死连接，浪费 FD 和内存。

## 诊断

```bash
# 查看 keepalive 参数
sysctl net.ipv4.tcp_keepalive_time    # 7200 秒（空闲多久开始探测）
sysctl net.ipv4.tcp_keepalive_intvl   # 75 秒（探测间隔）
sysctl net.ipv4.tcp_keepalive_probes  # 9 次（最多探测次数）
# 死连接回收最长 = 7200 + 75 × 9 = 7875 秒 ≈ 2.2 小时
```

## 修复

```bash
sysctl -w net.ipv4.tcp_keepalive_time=300    # 5 分钟空闲开始探测
sysctl -w net.ipv4.tcp_keepalive_intvl=30    # 30 秒探测间隔
sysctl -w net.ipv4.tcp_keepalive_probes=3    # 3 次探测后认为已死
# 死连接回收最长 = 300 + 30 × 3 = 390 秒 ≈ 6.5 分钟
```

## 或者用应用层心跳

对于对延迟敏感的协议，TCP keepalive 的分钟级粒度不够精细。可以在应用层每 30 秒发一个 PING 包，超时 3 次即断开。

## 验证

```bash
# 再次模拟死连接
kill -9 <client_pid>
# 等待 6.5 分钟
ss -tan | grep ESTAB | grep <server_port> | wc -l
# 死连接已被回收
```

## 关键指标记录

| 参数 | 默认值 | 优化后 |
|------|--------|--------|
| `tcp_keepalive_time` | 7200s (2h) | 300s (5min) |
| `tcp_keepalive_intvl` | 75s | 30s |
| `tcp_keepalive_probes` | 9 | 3 |
| 死连接最长存活 | 2.2h | 6.5min |

> **一句话总结**：2 小时的 keepalive 默认值在百万连接场景下是个灾难——一次网络闪断可能导致数十万"活死人"连接占据 FD 和内存长达 2 小时。调低到 5 分钟级别是长连接运维的基本素养。
