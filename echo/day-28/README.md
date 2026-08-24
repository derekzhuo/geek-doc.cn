# Day 28: L2 带计算 Echo (Compute Echo — CPU/Network Mixed Bottleneck)

> 所属阶段：阶段 8 — 进阶与复盘

## 今日目标

启动 L2 版本的 Echo 服务，在收发之间插入可调 CPU 运算权重，用 perf 观测 CPU 微架构瓶颈。

## L1 vs L2

| 维度 | L1 裸 echo | L2 带计算 echo |
|------|------|------|
| 处理流程 | read → write | read → **do_compute()** → write |
| CPU 热点 | 几乎全是内核（协议栈） | 用户态计算占比显著 |
| IPC 预期 | ~2.0（协议栈代码密集） | 随计算权重下降 |

## 启动 L2

```bash
# L2: 带计算 echo（每个请求做 N 次异或运算）
./bin/echo-server-compute --port 9090 --workers 8 --compute-weight 1000 --compute-mode xor &

# 压测
./bin/echo-client --server 127.0.0.1 --port 9090 --conn 10000 --mode long --rate 100 &

# perf 观测
perf stat -e cycles,instructions,IPC,LLC-loads,LLC-load-misses -p $(pidof echo-server-compute) sleep 30
```

## 对比实验

```bash
# 不做计算（weight=0，行为和 L1 一样）
--compute-weight 0

# 轻计算（weight=100，~100 次异或）
--compute-weight 100

# 重计算（weight=10000，~10000 次异或）
--compute-weight 10000
```

| weight | IPC | LLC miss | QPS | 瓶颈位置 |
|--------|-----|------|-----|------|
| 0 | ~2.0 | 低 | 极高 | 内核协议栈 |
| 100 | 待记录 | 待记录 | 待记录 | 用户态 + 内核混合 |
| 10000 | 待记录 | 待记录 | 待记录 | 用户态计算为主 |

## 关键指标记录

| 指标 | weight=0 | weight=100 | weight=10000 |
|------|------|------|------|
| IPC | 待记录 | 待记录 | 待记录 |
| QPS | 待记录 | 待记录 | 待记录 |
| %usr | 待记录 | 待记录 | 待记录 |

> **一句话总结**：L2 让瓶颈从内核层"浮出水面"到用户态——当你看到 IPC 下降和 QPS 下降同步时，瓶颈就在用户态计算代码里。这是 perf 分析用户态程序的最佳练习场景。
