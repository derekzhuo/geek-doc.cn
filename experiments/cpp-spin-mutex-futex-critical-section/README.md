# 自旋锁、互斥锁与自适应锁的临界区长度扫档基准

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-spin-mutex-futex-critical-section.html （随站点发布生效）

同一组共享计数器负载下对照三种锁的每次 lock-unlock 平均开销：

| 锁 | 实现 | 竞争失败时的行为 |
|---|---|---|
| spin | `std::atomic_flag` 纯自旋 | 用户态忙等，不进内核 |
| mutex | `std::mutex`（glibc pthread 互斥量） | futex 系统调用休眠，被唤醒后重新抢锁 |
| adaptive | `PTHREAD_MUTEX_ADAPTIVE_NP` | 先有限次自旋，仍抢不到再走 futex 休眠（Linux/glibc 专属） |

临界区六个等级：`w1/w30/w300/w3000/w30000` 为受控运算循环，`sleep100us` 在临界区内
`nanosleep` 100 微秒。程序启动时先单线程无锁校准每级临界区的实际平均耗时并打印
`CALIB` 行，结果解读以校准值为准。

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/main.cpp` | 三锁实现、六临界区级、1/2/4/8 线程扫档与无锁校准 |
| `Makefile` | `-O2 -std=c++17 -pthread` 构建，产物在 `bin/`（不入库） |
| `run.sh` | 完整基准 5 次取 ns_op 中位，再用 `perf stat` 采 4 线程代表配置 |
| `results.txt` | 最近一次 `run.sh` 的完整输出 |

## 复现方式

```bash
make            # 产出 bin/lock_bench
bash run.sh     # 数分钟，结果写入 results.txt
# 只跑某个配置（perf 采证用）：
FILTER_LOCK=spin FILTER_CS=w1 FILTER_THREADS=4 ./bin/lock_bench
```

## 测量口径与边界

- 指标是每次 lock-unlock 的平均纳秒数（总墙钟除以总操作数），包含临界区本身的
  运算时间，比较的是同一临界区下三种锁的相对开销，不是锁原语的孤立延迟；
- 外层 5 次独立进程取中位，压单次调度噪声；
- 测试机为 1 物理核 2 SMT 线程的云主机，4/8 线程属于超额订阅场景，上下文切换
  数字只代表该拓扑，不要外推到多核物理机；
- `PTHREAD_MUTEX_ADAPTIVE_NP` 是 glibc/Linux 专属类型，macOS 无此接口，本工程
  只在 Linux 上复现。
