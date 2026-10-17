# E2 百万长连接实验原始记录（2026-10-18 夜）

## 环境

- 服务端 / 客户端各一台腾讯云上海区竞价实例 S9.8XLARGE64（32C64G，TencentOS），内网互联
- 服务端内网地址以 `<server-internal-ip>` 代称（<server-internal-ip> 段），客户端 21 个辅助源 IP（<client-src-subnet>）
- 内核参数（两侧）：fs.file-max=4194304、fs.nr_open=4194304、somaxconn=65535、ulimit -n 2097152；nf_conntrack 未加载
- 服务端 keepalive（仅 T11 阶段调快）：tcp_keepalive_time=60、tcp_keepalive_intvl=10、tcp_keepalive_probes=3

## 文件说明

| 文件 | 内容 |
|---|---|
| `e2-ramp-1m.log` | T10/T12 客户端日志：50 秒爬到 est≈100 万（稳定 20K/s），随后 HOLD 660 秒零跌落 |
| `e2-srv.log` | 服务端日志（同一进程覆盖 T12 与 T11）：estab 峰值 1000072，RSS 仅 ~2.3MB |
| `e2-srv-poll.log` | 服务端内核态轮询（ss -s / meminfo / sockstat / slabinfo，每 5 秒），含空载基线 |
| `e2-ramp-t11.log` | T11 客户端日志：重建 100 万后被服务端 keepalive 回收、收到 RST 后 dropped 归零过程 |

## 三方对账（T12 峰值时刻）

- 客户端应用计数 est=998537（dropped=1535，为启动期服务端旧实例残留连接）
- 客户端内核 `ss -s`：estab 1000076
- 服务端内核 `ss -s`：estab 1000076；服务端应用计数 estab=1000072；fd 数 1000142

## 单连接内核内存成本

- 空载基线（estab=5，ts 1792259482 附近）：见 e2-srv-poll.log 开头
- 1M 时刻：服务端 Slab 4580488 kB、SUnreclaim 3417080 kB、MemFree 58954740 kB（总 64G）
- sockstat：`TCP: inuse 1000108 mem 3585`（TCP 页 3585×4KB ≈ 14MB 接收/发送缓冲占用，hold 无流量）
- TCP slab：83438 对象活跃

## T11 keepalive 回收曲线（服务端观测，断流点 T0=1792262006，iptables DROP <client-src-subnet>）

| T+秒 | 服务端 estab |
|---|---|
| 0 | 1000288 |
| 44 | 675988 |
| 75 | 178824 |
| 105 | 4 |

约 105 秒 100 万死连接全部回收（60s 首次探测 + 3×10s 重试，与参数吻合；早于 90s 开始是因为爬升期早建的连接空闲计时先到点）。服务端回收时发送 RST，客户端随之 dropped 归零（e2-ramp-t11.log 尾部 est 出现 -1024 是客户端计数器对重复 RDHUP 事件的已知小瑕疵，以内核 ss 为准）。

## 踩坑记录（文章素材）

1. echo-mt-server（day-04 教学版）在 fd>65535 时 `conns[fd]` 越界段错误 —— fd 索引数组必须以上限或动态结构存储
2. epoll 建连计数必须按 fd 状态翻转计一次，不能按事件计（曾 est=100 万实际 6.5 万）
3. **SO_REUSEADDR 不能用于海量出向连接**：它让 bind 放弃端口冲突检查，把四元组唯一性推给 connect，~29 万连接后 connect 100% EADDRNOTAVAIL、bind 退化到 10ms+/次
4. 即使去掉 SO_REUSEADDR，内核 bind(0) 临时端口搜索在 ~50 万绑定后仍退化到 34ms+/次（bhash 链扫描）；百万级客户端必须**应用侧显式分配端口**（本实验：21 IP × 55001 端口游标），改后稳定 20K/s 直达 100 万
5. ssh 挂后台进程必须 `setsid nohup ... < /dev/null`，否则会话被 stdout 挂住；`pkill -f` 会误杀自身命令行，用 `pkill -x`
