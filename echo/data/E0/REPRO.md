# E0 基线复核：253.3 万 QPS 验真（2026-10-14）

> 目的：复核 day-04 v3 报告的 **253.3 万 QPS（8 线程）** 是否可复现。
> 结论：**未复现**。8 线程实测 ~131–137 万；240 万级峰值出现在 **32 线程**（多次稳态 2.38–2.44M，含 332 秒长稳态 2,408,581 req/s）。253.3 万与 240 万差 ~6%，属同量级，疑似原报告线程口径或测量窗口问题。

## 环境

- 两台腾讯云 CVM（ap-shanghai，SPOTPAID 竞价，同 VPC 内网直连）：
  - 服务端：32 vCPU / 128G，运行 `echo-mt-server 9988 32 lt`（32 个 SO_REUSEPORT 监听套接字）
  - 客户端：32 vCPU / 128G，运行 `echo-kp-bench`（每连接一线程）
- 代码：与本仓库 day-04 v3 完全相同的 `echo-mt-server.c` 与 `echo-kp-bench`（未改一行）
- 实例已在数据回传确认完整后**当场销毁**（DescribeInstances TotalCount=0 确认），费用 <¥5（预算 ¥50 内）

## 复现命令

```bash
# 服务端
./echo-mt-server 9988 32 lt

# 客户端（<threads> 控制压测线程数；1000 连接 × N rounds）
./bin/echo-kp-bench <server-vpc-ip> 9988 1000 <rounds> --mode long

# 三口径观测（服务端）
sar -n DEV 1            # 网卡 PPS
ethtool -S eth0         # rx_queue_*_packets 前后差分
perf record -a -g -F 199 -- sleep 30   # 热相采样（需 pps 触发，见下文坑）
```

## 核心数据（bench/ 目录原始文件）

### 线程阶梯（1000 连接 × 1000 rounds，三轮取代表值）

| 压测线程 | QPS（三轮） | 备注 |
|---|---|---|
| 1 | 270,172 / 271,663 / 272,822 | |
| 2 | 427,673 / 419,037 / 419,044 | |
| 4 | 750,490 / 729,123 / 761,644 | |
| **8** | **1,307,704 / 1,327,398 / 1,298,618** | **253.3 万@8线程未复现，实测 ~131–137 万** |
| 16 | 2,022,311 / 1,990,571 / 2,103,220 | |
| **32** | **2,402,767 / 2,347,378 / 2,319,995** | 240 万级峰值在 32 线程 |

### 长稳态（1000 连接 × 800000 rounds，332–336 秒连续热相）

| 轮次 | elapsed | QPS |
|---|---|---|
| bg13 | 336.144 s | 2,379,929 |
| bg15 | 332.146 s | 2,408,581 |

### 突发 vs 稳态

- 突发（rounds=100，热相仅 0.128s）：778,349 QPS —— **突发 < 稳态**，短窗口吃不满管线。

### 三口径对齐（ethtool -S 前后差分 vs 应用层请求数）

| 轮次 | 应用 QPS×elapsed（请求数） | NIC rx_packets 差分 | 比例 |
|---|---|---|---|
| t1-r1 | 999,909 | 1,005,048 | ~1:1 |
| t8-r1 | 1,000,393 | 1,005,047 | ~1:1 |
| t32-r1 | 999,551 | 1,005,030 | ~1:1 |
| steady-r3000 | 3,000,009 | 3,005,043 | ~1:1 |

应用层 QPS 与网卡包数 1:1 对齐，数据可信。多出的 ~5k 包是 TCP 建连/ACK 开销。

### 热相 perf 画像（perf/report7.txt，pps>30k 触发的 30 秒热相采样）

- 触发时 /proc/net/dev 实测 pps ≈ 290 万/s，与应用 QPS 同量级
- `echo-mt-server` 线程占 57%（热点链：`__libc_write` → `ksys_write` → `vfs_write`，28.4%）
- swapper 仍占 ~42%：**32 核跑 240 万 echo/s 系统天然近半 idle**，write() 系统调用路径是唯一热点

## 测量陷阱记录（教训）

1. **腾讯云 VM 上 `ss` 不可信**：热相期间 `ss -tnH | grep -c :9988` 恒为 0，但 tcpdump 抓包证明 SYN/数据流完全正常。本环境不能用 ss 做连接计数。
2. **sar 窗口对齐**：kp-bench 有超长 ramp（1000 线程 spawn+connect 需数分钟），热相仅 0.1–336 秒不等；sar  averaging 窗口若覆盖 ramp 会把 240 万 QPS 摊成 10 万 pps（GRO 表象实为窗口错位）。
3. **perf 采样必须 pps 触发**：固定 sleep 后采样全部落空（采到 98% idle 的 swapper）；正确做法是轮询 /proc/net/dev 的 eth0 包速率，>30k pps 时再开 perf record。
4. **短轮次（elapsed <1s）的 QPS 抖动大**，结论只能信长稳态轮。

## 数据清单

- `bench/`：各轮次 kp-bench 原始输出（线程阶梯 + 突发/稳态 + 长稳态 bg13/bg15）
- `sar/`：对应轮次 sar -n DEV 采样
- `eth/`：ethtool -S 前后快照（before/after 成对）
- `cpu/`：mpstat 采样
- `perf/`：report.txt（空闲对照）+ report7.txt（热相，pps 触发）

所有文本已过 `sanitize-secrets.mjs --check`（IP/实例 ID 全部占位化）；本批无截图（全文本采集），shots 件豁免。
