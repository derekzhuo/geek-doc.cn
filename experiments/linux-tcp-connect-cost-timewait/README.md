# 短连接建连成本：TIME_WAIT 与临时端口压力实测

**对应教程**：https://geek-doc.cn/concepts/network/linux-tcp-connect-cost-timewait.html （随站点发布生效）

在 2 vCPU/8 GiB 云主机上用 loopback 打本机 nginx，对照四种内核配置下短连接
风暴的建连速率、失败数与 TIME_WAIT 堆积。每轮 4 万请求、128 并发，ab 每请求
一条新连接（无 keep-alive），主动关闭方在客户端，TIME_WAIT 全堆积在客户端侧。

## 四个对照例

| 用例 | tcp_max_tw_buckets | 临时端口段 | tcp_tw_reuse | 节奏 | 预期现象 |
|---|---|---|---|---|---|
| guard | 4096（系统默认） | 32768–60999 | 0 | 单轮 | 零失败，TCPTimeWaitOverflow 上涨，内核溢出回收兜底 |
| baseline | 200000 | 32768–60999 | 0 | 三轮，轮间等 62 秒老化 | 零失败，TW 完整留存后自然老化 |
| squeezed | 200000 | 40000–41499（1500 个） | 0 | 三轮连发 | 端口耗尽，`Cannot assign requested address` |
| squeezed-reuse | 200000 | 40000–41499（1500 个） | 1 | 三轮连发 | TW 端口复用，零失败 |

## 目录结构

| 文件 | 作用 |
|---|---|
| `bench.sh` | 四用例对照，自动备份/恢复端口段、tw_reuse、max_tw_buckets 三个 sysctl，产 ab 输出、ss 快照与 nstat 计数 |
| `results/` | 完整运行日志与每轮 ab 百分位 CSV |

## 复现方式

```bash
sudo apt-get install -y nginx apache2-utils
sudo -E bash bench.sh
# 可调参数：N=60000 C=128 ROUNDS=5 sudo -E bash bench.sh
```

## 测量口径

- ab 每次请求都是一条新 TCP 连接，主动关闭方在客户端，TIME_WAIT 堆积在
  本机 loopback 客户端侧；
- 三个 sysctl（端口段、tw_reuse、max_tw_buckets）由脚本统一设置，退出时
  trap 自动恢复原值；
- 失败分两类记录：ab 汇总行的 Failed requests 与 apr 套接字报错
  （`Cannot assign requested address`，即临时端口耗尽）；
- 每轮前后各取一次 `ss -ant state time-wait` 计数与 `ss -s` 汇总，每个
  用例前后各取一次 nstat 快照（TcpAttemptFails / TcpExtTW /
  TCPTimeWaitOverflow 等），区分「应用零失败但内核在默默回收」与
  「端口真正耗尽、错误冒泡到应用」两种状态。
