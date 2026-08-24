# Day 5: FD 与 ulimit 深入理解 (Understanding File Descriptors & ulimit)

> 所属阶段：阶段 2 — 多线程扩展与 FD 上限
> 更新时间：2026-08-20（FD 已实测：Day 4 的 [FD 墙实测](/demos/echo/day-04/fd-wall-experiment.md) 已用 `ulimit -n` 主动降档撞墙；Day 5 主线实验 [FD 机制实测](/demos/echo/day-05/fd-mechanism-experiment.md) 拆三层限制/软硬机制/EMFILE 空转；2026-08-20 补两个缺口——[持续空转实测](/demos/echo/day-05/sustained-spin-experiment.md)（连接数 ≫ FD 上限：EMFILE 洪泛 + 连接失败 + QPS 崩塌 200 倍）与 [四层链诊断](/demos/echo/day-05/ulimit-chain-experiment.md)（"改完 ulimit 不生效"的 C1~C4 成因逐个实测））

## 今日目标

不急于改参数，先把 FD 的**概念**彻底搞懂——它到底是什么、存在哪里、如何限制。

## FD 三层限制模型

```bash
┌─────────────────────────────┐
│  进程级: ulimit -n (RLIMIT_NOFILE)   │ ← accept()/socket() 直接受此限制
├─────────────────────────────┤
│  会话级: systemd LimitNOFILE          │ ← 覆盖 ulimit 的初始值
├─────────────────────────────┤
│  系统级: fs.nr_open                  │ ← 内核允许的绝对上限
│          fs.file-max                 │ ← 系统范围内所有进程 FD 总数上限
└─────────────────────────────┘
```

## 要做什么

### 1. 逐一查看三层限制

```bash
# 进程级（软限制/硬限制）
ulimit -Sn     # 软限制: 1024
ulimit -Hn     # 硬限制: 4096 (或 1048576)

# 系统级
cat /proc/sys/fs/file-max     # 系统级总 FD 上限
cat /proc/sys/fs/file-nr      # 已分配/空闲/上限
cat /proc/sys/fs/nr_open      # 单个进程 FD 上限
```

### 2. systemd 限制（如果使用 systemd 管理服务）

```bash
cat /etc/systemd/system/echo-server.service
# 如果没有 LimitNOFILE=，则 systemd 使用默认值
```

### 3. 理解 socket 和 FD 的关系

```bash
# 进程的每个 socket 都以 FD 形式存在
ls -la /proc/$(pidof echo-server)/fd/
# lrwx------ 1 root root  64 ...  0 -> /dev/pts/0     (stdin)
# lrwx------ 1 root root  64 ...  1 -> /dev/pts/0     (stdout)
# lrwx------ 1 root root  64 ...  2 -> /dev/pts/0     (stderr)
# lrwx------ 1 root root  64 ...  3 -> socket:[12345] (listen fd)
# lrwx------ 1 root root  64 ...  4 -> socket:[12346] (client fd)
# ...
```

### 4. FD 的本质

FD（File Descriptor，文件描述符）是进程打开的文件/socket/pipe 等资源的**索引号**，是一个非负整数。内核通过 FD 找到对应的 `struct file` 对象。

## 关键指标记录

| 限制层级 | 参数 | 当前值 |
|------|------|------|
| 进程软限制 | `ulimit -Sn` | 100001（limits.conf 生效值） |
| 进程硬限制 | `ulimit -Hn` | 100002 |
| 系统级 | `fs.file-max` | 1000000 |
| 系统级 | `fs.nr_open` | 1048576 |

> 实测详情见 [FD 机制实测：三层限制、软/硬限制与 EMFILE 空转](/demos/echo/day-05/fd-mechanism-experiment.md)（2026-08-18 上机实测：E1 三层基线 / E2 软硬机制 / E3 EMFILE 行为 / E4 FD 守恒）。
>
> **Day 5 补充实验（2026-08-20 上机实测）：**
> - [持续空转实测](/demos/echo/day-05/sustained-spin-experiment.md)：把连接数/FD 上限拉到 3x~78x 双模式对照——拐点在 15x~39x 之间，≥39x 起连接开始失败；"持续空转"真实形态是 EMFILE 洪泛（最多 4.8 万次）+ QPS 崩塌（12.9 万→520~770），CPU 峰值随比例上升但忙循环始终是波次脉冲；
> - [四层链诊断](/demos/echo/day-05/ulimit-chain-experiment.md)：C1 会话内修改不持久（新会话还原 100001）、C2 交互/非交互无差异、C3 root 也抬不过 `fs.nr_open`、C4 非 root 抬 hard 报 `Operation not permitted` 且 root 也逃不过 sudo 继承 rlimit。

> **一句话总结**：FD 不只是 `ulimit -n`——它是一个三层漏斗结构（进程→会话→系统），理解这三层对于后续诊断"为什么改完 ulimit 还是不生效"至关重要。

