# systemd 单元资源指令到 cgroup v2 接口的对照实验

**对应教程**：https://geek-doc.cn/concepts/container/linux-systemd-unit-resource-limits.html （随站点发布生效）

在 2 vCPU / 8 GB 云主机（Ubuntu 22.04，systemd 249，cgroup v2）上用 `systemd-run`
创建三个测试单元，对照 MemoryMax / MemoryHigh / MemorySwapMax / CPUWeight
四条指令分别落到哪个 cgroup v2 文件，以及各自的行为后果。

| 案例 | 配置 | 观察到的结果 |
|---|---|---|
| A 硬限禁swap | `MemoryMax=60M` + `MemorySwapMax=0`，120 MiB 工作集 | 内存接口写入 `memory.max=62914560`、`memory.swap.max=0`；单元 `Result=oom-kill`、`ActiveState=failed`，dmesg 出现 `CONSTRAINT_MEMCG` |
| B 软限换出 | `MemoryHigh=80M` + `MemorySwapMax=120M`，120 MiB 工作集 | `memory.high=83886080`、`memory.swap.max=125829120`；`high` 事件 1634 次，20s 正常跑完 |
| C CPU 权重 | 双单元各 2 个 runner 超额订阅 2 vCPU，`CPUWeight=100` vs `1000` | `cpu.weight` 分别 100/1000；10 秒处 usage_usec 比 9.4:1，贴近理论 10:1 |

## 目录结构

| 文件 | 作用 |
|---|---|
| `run-lp20.sh` | 三案例驱动：systemd-run 创建单元、运行中采样 cgroup 接口与 memory.events、等待终态后取状态 |
| `results/lp20-master.log` | 本次完整原始输出：指令落点、接口值、事件计数、journal 与内核 OOM 记录、CPU 时间序列 |

## 复现方式

需要 root 与 stress-ng（`apt-get install stress-ng`），内核须为 cgroup v2 统一挂载。

```bash
sudo bash run-lp20.sh
```

两个采样细节决定能否复现：单元进入终态后 systemd 会清掉 ControlGroup 等属性，
必须在运行中查询；不加 `--collect` 才能让失败单元保留到终态查询。
CPUWeight 只在 CPU 有竞争时改变时间分配，单 runner 各占一核时两组耗看不出差别。
