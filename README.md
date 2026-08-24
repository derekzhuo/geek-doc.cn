# geek-doc.cn — Linux 系统实验可复现代码集

> 与《Linux 性能剖析》站点（geek-doc.cn）配套的**可运行实验代码**。
> 每个 demo 独立可编译、可运行，`make run` 即出结果。

## 快速开始

```bash
git clone --depth 1 https://github.com/derekzhuo/geek-doc.cn.git
cd geek-doc.cn
make -C cpu-demo run        # 跑第一个 demo：CPU 使用率三场景
```

> 运行要求：Linux（demo 依赖 `/proc`、`perf` 等）。macOS 可编译多数 demo，但部分输出不同。

## 目录总览

| # | demo | 主题 | 运行 |
|:-:|------|------|------|
| D1/D2 | [cpu-demo](cpu-demo/) | CPU 使用率三场景 + perf stat/record 基础 | `make -C cpu-demo run` |
| D3 | [tlb-thrashing](tlb-thrashing/) | TLB 页表缓存抖动实验 | `make -C tlb-thrashing run` |
| D4 | [cache-miss](cache-miss/) | 缓存未命中模式（顺序/随机/跨步） | `make -C cache-miss run` |
| D5 | [branch-predict](branch-predict/) | 分支预测（有序/随机/无分支） | `make -C branch-predict run` |
| D6 | [stall-analysis](stall-analysis/) | 流水线停顿（前端 vs 后端） | `make -C stall-analysis run` |
| D7 | [syscall-trace](syscall-trace/) | 系统调用追踪实验 | `make -C syscall-trace run` |
| D8 | [lock-contention](lock-contention/) | 锁争用诊断实验 | `make -C lock-contention run` |
| D9 | [false-sharing](false-sharing/) | 伪共享检测实验（perf c2c） | `make -C false-sharing run` |
| D10 | [sched-latency](sched-latency/) | 调度延迟诊断实验 | `make -C sched-latency run` |
| D11 | [perf-probe](perf-probe/) | 动态探针插桩实验（perf probe/USDT） | `make -C perf-probe run` |
| D12 | [perf-bench-diff](perf-bench-diff/) | 微基准 + 优化对比实验 | `make -C perf-bench-diff run` |
| D13 | [indirect-branch](indirect-branch/) | 间接分支预测（虚函数/函数指针/switch） | `make -C indirect-branch run` |
| D14 | [mt-io-demo](mt-io-demo/) | 多线程 + IO 分析方法演练 | `make -C mt-io-demo run` |
| - | [compiler-reordering](compiler-reordering/) | 编译器重排与 data-race UB | `make -C compiler-reordering run` |
| - | [crash-signals](crash-signals/) | 崩溃信号复现（10 个程序） | `make -C crash-signals run` |

## 常用命令

```bash
make -C <demo>            # 编译（默认 -O0 -g，保留 perf 符号）
make -C <demo> run        # 编译并运行
make -C <demo> release    # 以 -O2 编译对比（观察优化器效果）
make -C <demo> clean      # 清理
```

## 配套理论文档

每个实验的理论讲解、工具使用与原始输出分析见配套站点（文档站，搜索「性能剖析」即可）。

## 许可

[MIT](LICENSE) — 自由使用、修改、再分发，仅需保留版权声明。
