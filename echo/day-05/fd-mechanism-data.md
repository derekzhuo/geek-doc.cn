# FD 机制实测（Day 5 主线实验）：五、实验数据

> 所属实验：[FD 机制实测（Day 5 主线实验）](/demos/echo/day-05/fd-mechanism-experiment.md) · 更新时间：2026-08-21（从主线拆出，内容零丢失）
> 上一篇：[主线一~四（问题/设计/代码/预期）](/demos/echo/day-05/fd-mechanism-experiment.md)
> 下一篇：[实验分析（六~八）](/demos/echo/day-05/fd-mechanism-analysis.md)

---

> 采集环境：124.221.142.185（CentOS 7 / 内核 3.10 / 4 核 EPYC），工具在 `/home/chzhuo/fd-experiment/`。
> 原始输出：服务器 `/tmp/exp51_52.out`（E1/E2）、`/tmp/exp34.out` 与 `/tmp/day5_e34/`（E3/E4）。

### 5.1 三层限制基线（E1）

<details>
<summary>📄 原始输出（点击展开）</summary>

```
##### [E1] 三层限制基线 #####
--- 进程级 ulimit (当前 ssh 会话)
soft=100001 hard=100002
--- 系统级 fs.*
file-max=1000000
nr_open=1048576
file-nr=1728	0	1000000
--- limits.conf 生效行
* soft nofile 100001
* hard nofile 100002
root soft nofile 100001
root hard nofile 100002
* soft memlock unlimited
* hard memlock unlimited
--- systemd 服务 (echo-server)
(无 echo-server.service)
```

</details>

| 层级 | 参数 | 实测值 | 备注 |
|------|------|--------|------|
| 进程软限制 | `ulimit -Sn` | **100001** | limits.conf 生效值（不是默认 1024，也不是 Day 4 说的 65535） |
| 进程硬限制 | `ulimit -Hn` | **100002** | = soft + 1 |
| 会话级 | limits.conf | `* soft/hard nofile 100001/100002`；root 同值；另有 `memlock unlimited` | 无 systemd（无 echo-server.service），登录会话由 PAM 应用 |
| 系统级 | `fs.file-max` | **1000000** | 全系统 FD 总数上限 |
| 系统级 | `fs.nr_open` | **1048576** | 单进程硬上限（RLIMIT_NOFILE 的天花板） |
| 系统级 | `fs.file-nr` | **1728 / 0 / 1000000** | 当前已分配 1728，占用率 0.17% |

> **实测结论**：进程级 `100001 ≤ 100002`；系统级 `nr_open=1048576 > file-max=1000000` 属正常（nr_open 是单进程天花板、file-max 是全系统总数，两维度独立）。当前**进程级最紧**（100001），但距系统级还有 10 倍余量。

### 5.2 软/硬限制机制（E2，原始输出）

<details>
<summary>📄 原始输出（点击展开）</summary>

```
##### [E2] 软/硬限制机制 #####
--- 当前 soft=100001 hard=100002
--- 尝试调到 hard+10000 (> hard, 应失败)
/tmp/exp51_52.sh: line 22: ulimit: open files: cannot modify limit: Operation not permitted
rc=1 now=100001
--- 失败后当前值仍为 100001
--- 尝试提升到 hard (= hard, 应成功)
rc=0 now=100002
--- 降到 1024 (远低于 soft/hard, 应成功)
rc=0 now=1024
--- 再提升回 hard (soft<=hard 区间内, 应成功)
/tmp/exp51_52.sh: line 29: ulimit: open files: cannot modify limit: Operation not permitted
rc=1 now=1024
--- 新开子 shell 验证继承
child-soft=1024 child-hard=1024
```

</details>

| 操作 | 目标值 | rc | 实测后值 | 结论 |
|------|:---:|:---:|:---:|------|
| 抬到 hard 之上 | 110002 | **1** | 100001（不变） | `Operation not permitted`，符合 P2 |
| 提升到 hard | 100002 | **0** | 100002 | soft 可升到 hard，成功 |
| 降到 1024 | 1024 | **0** | 1024 | 成功，但**soft 与 hard 同时被改**（见 6.2） |
| 再抬回 hard | 100002 | **1** | 1024（锁死） | **hard 已被降至 1024，无法抬回** |
| 子 shell 继承 | — | — | child soft=1024 hard=1024 | 子进程继承降档后的限制 |

> 与预期 P2 的偏差：第 4 步"抬回 hard"本应成功，实际 `Operation not permitted`——因为第 3 步 `ulimit -n 1024` **裸用同时改写了 soft 和 hard**（见 6.2 分析）。

### 5.3 EMFILE 行为（E3，srv=128 / cli=65535 / 500 连接）

<details>
<summary>📄 原始输出（点击展开）</summary>

```
--- FD 峰值 ---
128
--- pidstat 高 CPU 行 (time UID PID TID %usr %system %CPU CPU Command) ---
14:39:08     1001     32003         -    0.00    0.00    0.00    0.00     3  echo-epoll-lt-s
14:39:08     1001         -     32003    0.00    0.00    0.00    0.00     3  |__echo-epoll-lt-s
14:39:07     1001     32003         -    1.00   18.00    0.00   19.00     3  echo-epoll-lt-s
14:39:07     1001         -     32003    1.00   18.00    0.00   19.00     3  |__echo-epoll-lt-s
14:39:06     1001     32003         -    2.00   21.00    0.00   23.00     0  echo-epoll-lt-s
14:39:06     1001         -     32003    2.00   21.00    0.00   23.00     0  |__echo-epoll-lt-s
--- bench 摘要 ---
 requests:        25000 / 25000 (ok:25000 fail:0)
 elapsed:         1.246 s
 QPS:             20062.9 req/s
```

</details>

| 指标 | 实测值 | 说明 |
|------|--------|------|
| FD 峰值 | **128** | 精确卡死在 ulimit=128，与 Day 4 "精确卡墙"完全一致 |
| 服务端线程 CPU | 峰值 **23%**（%system 21% + %usr 2%） | 窗口极短（bench 仅 1.2s），未出现持续 100% 空转 |
| QPS | **20062.9** | 500 连接 × 50 rounds 共 1.2s 完成 |
| fail | **0** | 与 Day 4 一致：连接被内核队列吸收 |
| EMFILE 计数 | 见服务器 `/tmp/day5_e34/srv-e3.log` | 脚本已落盘，本文未回拉正文 |

> 与 P3 的偏差：**500 连接 / 128 FD 只够 4 波排队（128−3≈125 连接/波），空转窗口被波次快速消化，CPU 峰值仅 ~23% 且一闪而过**——撞墙的 CPU 代价只在"连接数 ≫ FD 上限"的持续排队场景才显著，短窗口表现为瞬时脉冲而非 100% 空转（分析见 6.3）。

### 5.4 FD 守恒（E4，200 连接 × 5 轮）

<details>
<summary>📄 原始输出（点击展开）</summary>

```
A round=1 fd=5 est=4 tw=701      B round=1 fd=5 est=4 tw=1701
A round=2 fd=5 est=4 tw=901      B round=2 fd=5 est=4 tw=1901
A round=3 fd=5 est=4 tw=1101     B round=3 fd=5 est=4 tw=2101
A round=4 fd=5 est=4 tw=1301     B round=4 fd=5 est=4 tw=1602
A round=5 fd=5 est=4 tw=1501     B round=5 fd=5 est=4 tw=1402
```

</details>

| 对照组 | 第 1 轮 | 第 2 轮 | 第 3 轮 | 第 4 轮 | 第 5 轮 | 趋势 |
|--------|:---:|:---:|:---:|:---:|:---:|------|
| A 正常关闭 | fd=5 tw=701 | fd=5 tw=901 | fd=5 tw=1101 | fd=5 tw=1301 | fd=5 tw=1501 | **fd 持平、tw 单调 +200/轮** |
| B 客户端强杀 | fd=5 tw=1701 | fd=5 tw=1901 | fd=5 tw=2101 | fd=5 tw=1602 | fd=5 tw=1402 | **fd 持平、tw 先升后回落** |

> est 恒为 4（机器上其他会话的 established 连接），服务端 fd 每轮结束后都回到基线 **5**（stdin/stdout/stderr + listen_fd + epoll_fd），**无 FD 泄漏**。

> **一句话总结**：四组数据揭示了三个"精确"——FD 峰值精确卡墙（128=ulimit）、fail 恒为 0、fd 每轮精确回落基线 5；同时暴露一个"偏差"——E3 CPU 只有 23% 脉冲而非预期的 100% 空转，把"持续空转长什么样"的问题抛给了 [持续空转实测](/demos/echo/day-05/sustained-spin-experiment.md)。
