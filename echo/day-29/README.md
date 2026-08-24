# Day 29: L3 流式分包 Echo (Streaming Echo — Framing & Stick-Packet)

> 所属阶段：阶段 8 — 进阶与复盘

## 今日目标

启动 L3 版本的 Echo 服务，处理 TCP 流式传输中的粘包（Stick Packet）和拆包（Fragmentation）问题。

## L1 vs L3

| 维度 | L1 裸 echo | L3 流式分包 echo |
|------|------|------|
| 消息边界 | `read()` 一次就是一个消息（前提消息 ≤ buffer） | 需要帧头标识消息长度 |
| 粘包处理 | 无——依赖"一读一消息"的假象 | 必须处理"一次读到多个消息" |
| 缓冲区 | 无状态 | per-connection 累积缓冲区 |

## 帧协议

```bash
┌──────────────┬──────────────────┐
│  4 字节长度头  │      Payload      │
│  (uint32 BE) │   (长度头指定的字节数) │
└──────────────┴──────────────────┘
```

## 启动 L3 并验证粘包处理

```bash
# 启动 L3 echo
./bin/echo-server-stream --port 9090 --workers 8 &

# 用 L3 客户端压测（自动组帧）
./bin/echo-client-stream --server 127.0.0.1 --port 9090 --conn 100 --mode long --msg-size 4096

# 验证：发送 4KB 消息，收到的也是 4KB + 帧头
# 如果有粘包，帧头解析会出错（长度值异常）
```

## 要理解的核心问题

### 粘包（Stick Packet）
```bash
发送端:  msg1(100B) + msg2(100B)
TCP 流:  [100B][100B]
接收端:  一次 read() 读到 200B → 需要帧头分割
```

### 拆包（Fragmentation）
```bash
发送端:  msg1(4096B)
TCP 流:  [1500B] [1500B] [1096B]
接收端:  三次 read() → 需要累积凑齐 4KB
```

## 状态机设计

```bash
conn_state_t:
  buf[]        → 累积缓冲区
  buf_len      → 已累积字节
  expect_len   → 当前期望的消息长度（从帧头解析得到）
  state        → READ_HEADER | READ_PAYLOAD
```

## 关键指标记录

| 指标 | L1 | L3 |
|------|-----|-----|
| QPS | 极高 | 略低（解析开销） |
| 内存/连接 | ~6.5KB | + per-conn buffer |
| 消息正确率 | 100% | 100%（正确实现下） |

> **一句话总结**：L3 是 TCP 流式语义的工程实践——自定义帧协议、状态机解析、动态缓冲区管理，这三个要素是从"玩具 echo"到"准生产网关"的关键一步。粘包/拆包不是 bug，是 TCP 的本质特性。

