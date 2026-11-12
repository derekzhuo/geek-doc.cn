# ASan / TSan / UBSan 运行时开销：同一工作负载的五构建对照基准

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-asan-tsan-ubsan-overhead.html （随站点发布生效）

同一份混合工作负载（真实分配释放、16 MB 数组遍历、4000 万次整数算术、4 线程原子计数），
分别用裸 `-O2`、UBSan、ASan、ASan+UBSan、TSan 五种构建编译，量化 Sanitizer 运行时开销，
并实跑一个可控数据竞争的 TSan 报告与修复对照、一个 UBSan 检测演示。

## 目录结构

| 文件 | 作用 |
|---|---|
| `bench.cpp` | 四阶段混合负载，输出 `elapsed_ms` 与 `checksum`（五构建 checksum 必须一致） |
| `race_demo.cpp` | 两线程无同步自增；`-DRACE_FIXED` 切换为 atomic 修复版 |
| `ub_demo.cpp` | 运行期触发有符号整数溢出与非法移位，演示 UBSan 报告 |
| `Makefile` | 五变体 bench + race/race-fixed/ub-demo 共八个目标 |
| `run.sh` | 每变体 7 个独立进程取计时与 RSS 中位，计算相对裸档倍数，附检测演示 |
| `results.txt` | 一次完整运行的实测输出 |

## 复现方式

```bash
make
bash run.sh
```

计时在进程内用 `steady_clock` 完成，RSS 由进程外 `/usr/bin/time -l` 的
maximum resident set size 采集，每变体 7 个独立进程取中位。
注意 ASan 与 TSan 运行时互斥，不能在同一次链接中同时启用。

## 测量边界

倍数只描述本程序这种「分配密集 + 数组遍历 + 整数算术 + 短线程」形态下的实测开销，
不同工作负载（计算密集、长驻服务、海量线程）下倍数会明显漂移，不要外推为固定常数。
