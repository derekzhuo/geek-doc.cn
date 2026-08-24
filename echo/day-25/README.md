# Day 25: TIME_WAIT 优化 (TIME_WAIT Optimization — tcp_tw_reuse)

> 所属阶段：阶段 7 — 短连接专题

## 今日目标

优化 TIME_WAIT 堆积问题，用 `tcp_tw_reuse` 和 `tcp_fin_timeout` 降低 TW 回收时间。

## 当前状态

| 指标 | 值 |
|------|-----|
| TIME_WAIT 峰值 | ~3 万 |
| `tcp_tw_reuse` | 0（默认禁用） |
| `tcp_fin_timeout` | 60（默认 60 秒） |

## 两步优化

### 1. 开启 tcp_tw_reuse

```bash
sysctl -w net.ipv4.tcp_tw_reuse=1
```

作用：允许将 TIME_WAIT 状态的 socket 用于**新的出站连接**（客户端侧）。内核会检查时间戳，确保旧连接的数据包不会干扰新连接。

### 2. 降低 tcp_fin_timeout

```bash
sysctl -w net.ipv4.tcp_fin_timeout=15
```

作用：FIN_WAIT2 状态的最长存活时间从 60 秒降低到 15 秒。注意这影响的是 FIN_WAIT2（被动关闭方），TIME_WAIT 的持续时间由内核常量 TCP_TIMEWAIT_LEN 控制（固定 60 秒，不可调）。

## 对比测试

```bash
# 优化前
./echo-client --mode short --duration 30 --rate 5000
watch -n 1 'ss -s'  # 记录 TW 峰值

# 开启 tcp_tw_reuse + tcp_fin_timeout=15
sysctl -w net.ipv4.tcp_tw_reuse=1
sysctl -w net.ipv4.tcp_fin_timeout=15

# 优化后
./echo-client --mode short --duration 30 --rate 5000
watch -n 1 'ss -s'  # 记录 TW 峰值
```

## 预期结果

| 指标 | 优化前 | 优化后 |
|------|--------|--------|
| TW 峰值 | ~3 万 | ↓ 显著降低 |
| QPS | 基线 | ↑ 提升 20-30% |
| 连接成功率 | 基线 | ↑ |

## 注意事项

- `tcp_tw_reuse` 只对**客户端**（主动发起连接的一方）有效
- `tcp_tw_recycle` 已被 Linux 移除（4.12+ 不再使用），不要用它
- 在 NAT（Network Address Translation，网络地址转换）环境下要谨慎使用 tw_reuse

## 关键指标记录

| 指标 | 优化前 | 优化后 | 变化 |
|------|--------|--------|------|
| TW 峰值 | 待记录 | 待记录 | |
| QPS | 待记录 | 待记录 | |
| tcp_fin_timeout | 60 | 15 | -75% |

> **一句话总结**：短连接 TIME_WAIT 优化核心就两步——`tcp_tw_reuse=1` 允许端口复用，`tcp_fin_timeout=15` 加快超时回收。两个参数搞定，但前提是你必须先撞上 TIME_WAIT 爆炸，才理解为什么需要它们。
