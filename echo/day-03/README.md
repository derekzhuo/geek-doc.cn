# Day 3: 短连接 vs 长连接 — 消除 close() 后的性能跃迁

> 所属阶段：阶段 1 — 从零写出 Echo 服务
> 前置依赖：[Day 2 — epoll/多进程/短连接压测基线](/demos/echo/day-02/)
> 更新时间：2026-08-20（重构：按"一篇实验 = 一个知识点"拆分为 5 篇小实验；原单篇 39KB 文档拆分后各实验独立成文）
> **阶段小结**：[阶段 1 小结（Day 0-3）](/demos/echo/docs/01b-phase1-summary.md)

---

## 一、本 Day 在做什么

Day 2 通过 `strace -c` 发现：**短连接模式下，close() 占服务端总系统调用时间的 21-28%**（单次 close 耗时 35-58μs）。Day 3 用**同一把尺子**量短连接和长连接，验证一个预测：

> 改用长连接（connect 一次、多轮 echo、再 close），消除单次请求的 connect/close 开销，QPS 应有 **2-5×** 的提升。

Day 3 做的事很简单：**服务端本来就是长连接兼容的**（Day 2 的状态机天然支持 `STATE_WRITE → STATE_READ` 回路，服务端从不主动关连接），**客户端改一下策略**——原来每轮 `connect → send → recv → close`，现在改成 `connect → (send → recv) × R → close`。不需要协议扩展、不需要 HTTP 头、不需要内核参数，纯粹是**应用层连接管理策略的改变**。

## 二、名词澄清："Keep-Alive"指什么

Day 3 语境下的"Keep-Alive"是**应用层长连接**——客户端和服务端约定"TCP 连接建好后不关闭，复用同一条连接发多轮请求"。它不是以下任何一种：

| 不是 | 区别 |
|------|------|
| **HTTP `Connection: keep-alive`** | HTTP/1.1 默认行为，告诉对端"发完这个响应别关连接"。底层机制相同（复用 TCP 连接），但 Day 3 不涉及 HTTP 协议 |
| **TCP `SO_KEEPALIVE`** | 内核级 TCP 保活探测——连接空闲太久时发探测包确认对端还活着。与"复用连接发多轮请求"是两回事 |
| **HTTP/2 多路复用** | 在一条 TCP 连接上并发多个请求/响应流。Day 3 只是单线程串行复用，不涉及多路复用 |

> 所以 Day 3 的"Keep-Alive"其实就是"应用层长连接"——借用了 HTTP 的习惯叫法，但实现上更原始、更可控：没有协议头协商、没有超时规则、没有管线化，就是 TCP 连接不关而已。

## 三、本 Day 的 4 个问题 → 5 篇小实验

| # | 问题 | 实验 | 核心发现 |
|---|------|------|---------|
| Q1 | 长连接 QPS 实际提升多少倍？ | [实验 3.1 长连接 QPS 对比](/demos/echo/day-03/exp1-long-vs-short-qps.md) | ET **2.15×**（LT 仅 1.48×，被重复通知拖累） |
| Q2 | LT vs ET 差距是否终于显现？ | [实验 3.2 LT vs ET](/demos/echo/day-03/exp2-lt-vs-et.md) | **ET 高 37.2%**，远超 5-10% 预期 |
| Q3 | 并发连接数如何衰减、拐点在哪？ | [实验 3.3 连接数扫描](/demos/echo/day-03/exp3-conn-scale.md) | **500 连接拐点**，之后单线程天花板平台期 |
| 机制 | close() 真的被消除了吗？ | [实验 3.4 strace 实证](/demos/echo/day-03/exp4-strace-syscall.md) | close/connect 次数 **-90%**、耗时 **-87%** |
| Q4 | 跨网络延迟来自哪些层？ | [实验 3.5 跨网络部署](/demos/echo/day-03/exp5-cross-network.md) | 增量 ≈ **1-2 个网络 RTT**（9.1ms） |

> 阅读顺序：3.1 → 3.4（Q1 及机制）→ 3.2（Q2）→ 3.3（Q3）→ 3.5（Q4，可选）。

## 四、核心结论速览（Q&A 一行版）

| 问题 | 答案 |
|------|------|
| Q1 | ET 24915→53528（**2.15×**）；LT 26433→39010（1.48×）。与 Day 2 预测 2-5× 基本一致 |
| Q2 | 显现且超预期：长连接下 **ET 比 LT 高 37.2%**；差距全在 LT 的重复通知（P99 7481 vs 1894μs） |
| Q3 | 拐点 **500 连接**（100→500 掉 88%），之后 2700-3900 平台期；5000 短连接崩盘（QPS 387 + fail 248），长连接 3222 零失败 |
| Q4 | P50 增约 **4 倍**（长 3336→14442μs）；min 增量精确等于 1×RTT（长）/ 2×RTT（短），RTT=9.1ms |
| 机制 | close/connect 次数 **-90%**、syscall 总耗时 **-86.7%**（3.23s→0.43s） |

## 五、与 Day 2 的关键差异

| 维度 | Day 2（短连接） | Day 3（长连接） |
|------|:---------:|:---------:|
| 连接模型 | 每次请求：connect → send → recv → close | connect → N×(send → recv) → close |
| 主要瓶颈 | close() syscall（21-28%） | LT 的 epoll 重复通知（ET 高 37.2%） |
| LT vs ET | 几乎无差异 | ET 优势显现且超预期（37.2%） |
| 压测工具 | echo-bench.c（串行） | echo-kp-bench.c（并行，`pthread_barrier` 同步） |
| 最可复现的科学问题 | "为什么 close() 这么贵？" | "消除 close() 到底值多少 QPS？"（ET 2.15×） |

## 六、衔接后续

Day 3 把连接层瓶颈清空后，露出了下一层瓶颈：

| Day 3 暴露的瓶颈 | 证据 | 后续迭代方向 | 对应阶段 |
|------|------|------|------|
| 单线程 epoll 天花板 | 500 连接后 QPS 悬崖（掉 88%），5000 长连接仅 3222 | 多线程/多进程 **SO_REUSEPORT** + IRQ 亲和（[day-02 已有 `echo-mp-server.c`](/demos/echo/day-02/echo-mp-server.c)） | 阶段 2（Day 4-6）|
| LT 重复通知 | 长连接 ET 高 37.2% | 已换 ET；进一步 EPOLLONESHOT / 忙轮询 / 批量 readv-writev | 阶段 4 |
| 5000 短连接崩盘 | QPS 387 + fail 248 | TIME_WAIT 与端口耗尽治理（tcp_tw_reuse / fin_timeout / ip_local_port_range）| 阶段 3 + 7 |
| 跨网络延迟硬下限 | P50 ≈ 1-2 个网络 RTT | 网络层非本地可优化，改走长连接 + 多连接复用 | 阶段 6（百万长连接）|

> **一句话总结**：Day 3 的终点是 Day 4 的起点——"消除 close() 换来的吞吐优势，必须靠多核并行（多线程 + RSS 多队列 + IRQ 亲和）才能兑现"。

---

## 附录：操作清单

### 跑实验前的必备检查

```bash
# 1. 确认 ulimit（< 10000 时执行 ulimit -n 65535）
ulimit -n
# 2. 确认 sysctl
sysctl net.ipv4.tcp_tw_reuse
sysctl net.ipv4.tcp_fin_timeout
sysctl net.ipv4.ip_local_port_range
# 3. 确认端口未被占用
ss -tlnp | grep 9988
# 4. 编译
cd demos/echo/day-03 && make all
```

### 快速跑全部实验

```bash
# 终端 1：启动 LT 服务端
make run-lt
# 终端 2：一键全跑（3.1~3.4）
make run-all
```

### 本次实验命令记录（2026-08-12）

结果文件均留档于服务器 `/root/echo-day03/`。

**0. 环境准备（腾讯云 4 核 CentOS 7，公网 124.221.142.185）**

```bash
cd /root/echo-day03 && make all
# TIME-WAIT 不成为瓶颈 + 本地端口范围足够大
sysctl -w net.ipv4.tcp_tw_reuse=1
sysctl -w net.ipv4.tcp_fin_timeout=5
sysctl -w net.ipv4.ip_local_port_range="32768 60999"
ulimit -n 65535
nohup ./echo-epoll-lt-server > lt34.log 2>&1 &    # LT 版
nohup ./echo-epoll-server  > et34.log 2>&1 &      # ET 版
```

**1. 实验 3.1：LT/ET × 短/长连接，各 3 轮（结果 → `results31/`）**

```bash
for m in short long; do
  for i in 1 2 3; do
    ./echo-kp-bench 127.0.0.1 9988 100 10 --mode $m > results31/lt-$m-r$i.txt
  done
done
# 停 LT、启 ET 后重复，结果 → results31/et-$m-r$i.txt
```

**2. 实验 3.2：连接数扫描 100→5000（结果 → `results32/` 首测、`results32b/` 复测）**

```bash
for c in 100 500 1000 2000 5000; do
  ./echo-kp-bench 127.0.0.1 9988 $c 10 --mode short > results32b/scan-$c-short.txt
  ./echo-kp-bench 127.0.0.1 9988 $c 10 --mode long  > results32b/scan-$c-long.txt
done
```

**3. 实验 3.3：strace 对比 close/connect（结果 → `s33-short.sum` / `s33-long.sum`）**

```bash
strace -f -c -e trace=connect,close \
  ./echo-kp-bench 127.0.0.1 9988 100 10 --mode short 2> s33-short.sum
strace -f -c -e trace=connect,close \
  ./echo-kp-bench 127.0.0.1 9988 100 10 --mode long  2> s33-long.sum
```

**4. 实验 3.5：跨网络部署对比（Python 客户端，同一把尺子）**

```bash
# ① 服务器内 localhost 基线（结果 → results34/lo-*.txt）
for m in short long; do
  for i in 1 2 3; do
    PYTHONIOENCODING=utf-8 python3 bench_py.py 127.0.0.1 9988 100 10 --mode $m \
      > results34/lo-$m-r$i.txt
  done
done
# ② 本地 macOS 远程压测（结果 → results34/rm-*.txt，已回传服务器留档）
for m in short long; do
  for i in 1 2 3; do
    PYTHONIOENCODING=utf-8 python3 bench_py.py 124.221.142.185 9988 100 10 --mode $m \
      > results34/rm-$m-r$i.txt
  done
done
# ③ 前置：公网端口放行（安全组 + firewalld 9988/tcp）
firewall-cmd --permanent --add-port=9988/tcp && firewall-cmd --reload
```
