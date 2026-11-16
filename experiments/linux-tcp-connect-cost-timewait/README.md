# 短连接建连成本：TIME_WAIT 与临时端口压力实测

**对应教程**：https://geek-doc.cn/concepts/network/linux-tcp-connect-cost-timewait.html （随站点发布生效）

在 2 vCPU/8 GiB 云主机的 loopback 上做两组对照实验，回答一个问题：
TIME_WAIT 在什么条件下会耗尽客户端临时端口，`tcp_tw_reuse` 又能救回多少。

## 两组实验与关闭方归属

TIME_WAIT 属于**主动关闭方**，这是本实验最关键的前提。

| 实验 | 脚本 | 谁先关闭 | TIME_WAIT 落点 | 结果 |
|---|---|---|---|---|
| nginx/ab 四用例 | `bench.sh` | nginx 发完 HTTP/1.0 响应立刻关闭，服务端是主动关闭方 | 服务端 80 端口，不占 ab 临时端口 | 客户端零失败；guard 用例可见 `TCPTimeWaitOverflow` 静默回收 |
| C 客户端/服务端三用例 | `run-tw.sh`、`tw_server.c`、`tw_client.c` | 服务端回完响应故意延迟 500 ms 关闭，客户端先 FIN | 客户端临时端口 | 窄端口段下 EADDRNOTAVAIL 稳定复现 |

nginx/ab 组是一次有价值的否定性实验：在「服务端先关」的真实 HTTP 栈上，
loopback 压测复现不了临时端口耗尽。C 组把关闭方换成客户端后才真正打满端口池。

## C 组三个对照例（每用例 2 万次连接尝试，bucket 统一抬到 200000）

| 用例 | 临时端口段 | tcp_tw_reuse | 成功 | EADDRNOTAVAIL | 成功率 |
|---|---|---|---|---|---|
| baseline | 32768–60999（28232 个） | 0 | 20000 | 0 | 100% |
| squeezed | 40000–41499（1500 个） | 0 | 1500 | 18500 | 7.5% |
| squeezed-reuse | 40000–41499（1500 个） | 1 | 4002 | 15998 | 20.0% |

`squeezed` 的成功数恰好等于端口段大小，是端口池硬上限的直接证据。
`tcp_tw_reuse=1` 只救回 20%：复用要求 TW 存活超过约 1 秒的时间戳年龄窗口，
秒级突发里绝大多数 TW 还太年轻。

## 目录结构

| 文件 | 作用 |
|---|---|
| `bench.sh` | nginx/ab 四用例对照，自动备份/恢复端口段、tw_reuse、max_tw_buckets 三个 sysctl |
| `tw_server.c` | 延迟 500 ms 关闭的 loopback 服务端，让客户端成为主动关闭方 |
| `tw_client.c` | 64 线程客户端，按 errno 把失败归类为 EADDRNOTAVAIL 与其他错误 |
| `run-tw.sh` | 编译并跑 C 组三用例，带 ss/nstat 快照与 sysctl trap 还原 |
| `results/` | 完整运行日志与每轮 ab 百分位 CSV |

## 复现方式

```bash
# 第一组：nginx/ab（需要 nginx 与 apache2-utils）
sudo apt-get install -y nginx apache2-utils
sudo -E bash bench.sh

# 第二组：C 最小对，无需外部服务
sudo -E bash run-tw.sh
```

## 测量口径与已知边界

- 三个 sysctl（端口段、tw_reuse、max_tw_buckets）由脚本统一设置，退出时
  trap 自动恢复原值；
- `tw_client` 的成功口径是 `connect/send/recv/close` 全程未返回错误，
  不校验响应体内容（服务端响应固定为 3 字节 `ok\n`）；
- `tw_server` 预置了 EMFILE/ENFILE 防御分支，但按实测峰值约 1590 req/s、
  每连接持有 500 ms 估算，并发存活连接约 800 个，低于本机 1024 的
  `ulimit -n`，本次运行该分支未触发，日志中没有 EMFILE 证据；
- nstat 快照区分「应用零失败但内核在默默回收」（TCPTimeWaitOverflow）
  与「端口真正耗尽、错误冒泡到应用」（EADDRNOTAVAIL）两种状态。
