# STREAM 风格内存带宽基准（Copy / Scale / Add / Triad）

**对应教程**：https://geek-doc.cn/concepts/memory/linux-memory-bandwidth-stream-bench.html （随站点发布生效）

自写的 STREAM 风格四内核内存带宽微基准，在同一工作集上测量连续访存的可达带宽，
并沿 OpenMP 线程数扫档，观察虚拟机 vCPU（物理核 / SMT 兄弟线程）下的扩展形态。

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/stream_bench.c` | 四内核实现、20 轮计时、最佳/中位带宽汇总与结果校验 |
| `Makefile` | `-O3 -fopenmp -march=native` 构建，产物在 `bin/`（不入库） |
| `run.sh` | 1/2 线程各 7 次取中位，并用 `perf stat` 采系统侧事件 |
| `results.txt` | 最近一次 `run.sh` 的完整输出 |

## 复现方式

```bash
make            # 产出 bin/stream_bench
bash run.sh     # 约五分钟，结果写入 results.txt
```

## 测量口径

- 三数组各 1000 万个 double，单数组约 76.3 MiB、总工作集约 229 MiB，
  大于被测环境 L3（54 MiB）的四倍，访问落内存而非缓存；
- 每轮跑 Copy、Scale、Add、Triad 四个内核，共 20 轮，首轮预热丢弃，
  进程内取最佳值（STREAM 官方口径），外层脚本 7 次再取中位；
- 字节口径：Copy/Scale 每元素 16 字节（一读一写），Add/Triad 24 字节（两读一写）；
- 计时用 `omp_get_wtime`，线程数由 `OMP_NUM_THREADS` 控制；
- `perf stat` 需要 root（`kernel.perf_event_paranoid=4` 的云主机用 sudo），
  采 page-faults、context-switches、cache-misses、instructions、cycles；
- 云主机只分到物理核的部分内存带宽，实测值是虚拟化配额下的可达带宽，
  与裸机 STREAM 官方榜不可直接横比。
