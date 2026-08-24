# Day 7: 建连超时与端口范围 (Connection Timeout & Port Range)

> 所属阶段：阶段 3 — TCP 内核参数

## 今日目标

把连接数从 1 万推向 3 万，撞上第二个瓶颈——端口不够用。

## 前置状态

- FD 限制已解除，1 万连接稳定
- TCP 内核参数全部默认
- `ip_local_port_range` 默认 32768-60999（约 2.8 万）

## 预期 vs 实际

| | 预期 | 实际 |
|------|------|------|
| 连接数 | 3 万 | 约 2.7 万时开始超时 |
| 客户端 | 正常建连 | `connect()` 返回 -1，errno = EADDRNOTAVAIL |

## 撞上了什么

```bash
./echo-client --conn 30000 --mode long
# 前 2.7 万个连接正常
# 之后的连接: connect() failed: Cannot assign requested address (EADDRNOTAVAIL)
```

## 诊断步骤

```bash
# 1. 理解 TCP 四元组
# {源IP, 源端口, 目的IP, 目的端口}
# 客户端连接相同(server_ip, server_port)时，唯一性靠 源端口 区分

# 2. 查看可用端口范围
cat /proc/sys/net/ipv4/ip_local_port_range
# 输出: 32768  60999  → 只有约 28231 个可用端口

# 3. 确认端口已耗尽
ss -tan | grep '127.0.0.1:' | wc -l
# 输出: ~28230
```

## 修复

```bash
# 扩大端口范围到最大
echo "1024 65535" > /proc/sys/net/ipv4/ip_local_port_range

# 验证
cat /proc/sys/net/ipv4/ip_local_port_range
# 1024  65535 → 约 64511 个可用端口
```

## 重新测试

```bash
./echo-client --conn 30000 --mode long
# 全部成功！
```

## 但注意

长连接场景下，3 万端口够用（因为连接保持不释放）。如果是短连接（频繁建连断连），端口会快速进入 TIME_WAIT 且不能立即重用——这个问题后面阶段会遇到。

## 关键指标记录

| 指标 | 修复前 | 修复后 |
|------|--------|--------|
| `ip_local_port_range` | 32768-60999 | 1024-65535 |
| 最大客户端连接数 | ~28231 | 64511+ |
| 错误类型 | EADDRNOTAVAIL | — |

> **一句话总结**：端口耗尽是 FD 之后的第二个瓶颈——TCP 四元组的唯一性由源端口保证，默认 2.8 万个端口在 3 万连接时就撞上了，扩到 1024-65535 后可用 6.4 万个（还远远不够百万长连接的目标，后面还有更多优化）。
