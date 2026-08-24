# Day 26: 端口耗尽 — EADDRNOTAVAIL (Port Exhaustion)

> 所属阶段：阶段 7 — 短连接专题

## 今日目标

复现并修复短连接场景下的端口耗尽问题。

## 端口耗尽的本质

回顾 TCP 四元组：`{源IP, 源端口, 目的IP, 目的端口}`。

短连接每秒钟产生数千个新连接，每个连接都需要一个唯一的源端口。加上 TIME_WAIT 占着端口 60 秒不释放，可用的源端口很快就被耗尽。

## 复现端口耗尽

```bash
# 故意缩小端口范围，加速耗尽
echo "1024 2048" > /proc/sys/net/ipv4/ip_local_port_range
# 现在只有 ~1024 个可用端口

# 压测短连接
./echo-client --mode short --duration 30 --rate 5000

# 很快出现
# connect() failed: Cannot assign requested address (EADDRNOTAVAIL)
```

## 诊断

```bash
# 查看端口使用情况
ss -tan | awk '{print $4}' | grep -oP ':\d+$' | sort | uniq -c | sort -rn | head

# 查看端口范围
cat /proc/sys/net/ipv4/ip_local_port_range
# 1024 2048（太小！）

# 查看 TIME_WAIT 占用的端口
ss -tan state time-wait | wc -l
```

## 修复三步走

```bash
# 1. 扩大端口范围
echo "1024 65535" > /proc/sys/net/ipv4/ip_local_port_range

# 2. 开启端口复用
sysctl -w net.ipv4.tcp_tw_reuse=1

# 3. 降低超时
sysctl -w net.ipv4.tcp_fin_timeout=15
```

## 验证

```bash
# 恢复端口范围后重新压测
./echo-client --mode short --duration 60 --rate 5000
# 不再出现 EADDRNOTAVAIL
```

## 关键指标记录

| 指标 | 耗尽时 | 修复后 |
|------|--------|--------|
| 可用端口数 | ~1024 | ~65535 |
| EADDRNOTAVAIL | 大量 | 0 |
| TIME_WAIT 峰值 | 待记录 | 待记录 |

> **一句话总结**：端口耗尽的本质是"源端口不够用"——TIME_WAIT 占着茅坑 60 秒 + 端口范围太小 = EADDRNOTAVAIL。扩大端口到 1024-65535 + tw_reuse 解决 99% 的问题。
