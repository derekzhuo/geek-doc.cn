# arena 内存池（bump allocator）对照基准

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-arena-pool-allocator-benchmark.html （随站点发布生效）

面向批量短生命周期对象的 arena 实现：构造时一次性预留大块内存，`allocate()` 靠指针
碰撞（bump）切出对齐的对象空间，整批对象用完后 `reset()` 把指针回卷到块首，不逐个
free、不进分配器。工程同时提供带互斥锁的 `LockedArena`，用于量化多线程共享同一块
arena 时的锁竞争代价，并与裸 `new`/`delete` 正面对打。

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/main.cpp` | Arena / LockedArena 实现、operator new/delete 全套重载计数、单线程三档尺寸与多线程扫档负载 |
| `Makefile` | `-O2` / `-O0` 双目标，产物在 `bin/`（不入库） |
| `run.sh` | 两档各跑 7 次取中位，并用 `/usr/bin/time -l` 采 RSS、缺页与上下文切换 |
| `results.txt` | 最近一次 `run.sh` 的完整输出 |

## 复现方式

```bash
make            # 产出 bin/bench-O2 与 bin/bench-O0
bash run.sh     # 约两分钟，结果写入 results.txt
```

## 测量口径

- 单线程组：100 万个对象，尺寸 32/128/256 字节三档，全部建好并写入校验数据后
  批量销毁；裸路径逐个 new/delete，arena 路径 bump 分配加一次 reset；
- 多线程组：1/2/4/8 线程，每线程 20 万个 32 字节对象，三种形态——每线程独立
  new/delete、每线程独立 arena、全部线程共用带锁 arena；
- 所有分配结果都经过逃逸屏障（`asm volatile`）并按 16 字节步进写入，防止编译器
  消除分配、保证两条路径访存代价相同；
- 堆分配次数由重载的全局 `operator new`/`operator delete`（含对齐版）统计；
- 计时用 `std::chrono::steady_clock`，进程内 5 轮取中位，外层 7 次再取中位；
- macOS 无 perf，系统侧资源（RSS、缺页、上下文切换）由 `/usr/bin/time -l` 采集，
  其他平台与分配器（glibc malloc、jemalloc、tcmalloc）下的数字需重新实测。
