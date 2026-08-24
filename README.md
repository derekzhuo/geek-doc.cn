# geek-doc.cn — Linux 系统实验可复现代码集

> 与《Linux 性能剖析》站点 **https://geek-doc.cn** 配套的**可运行实验代码**。
> 每个 demo 独立可编译、可运行，`make run` 即出结果。

[![Site](https://img.shields.io/badge/站点-geek-doc.cn-blue?style=flat-square&logo=readthedocs&logoColor=white)](https://geek-doc.cn)
[![Demos](https://img.shields.io/badge/demo-15%20个可跑%2B1%20实战-orange?style=flat-square)](https://geek-doc.cn/demos/)

## 快速开始

```bash
git clone --depth 1 https://github.com/derekzhuo/geek-doc.cn.git
cd geek-doc.cn
make -C cpu-demo run        # 跑第一个 demo：CPU 使用率三场景
```

> 运行要求：Linux（demo 依赖 `/proc`、`perf` 等）。macOS 可编译多数 demo，但部分输出不同。
>
> 📖 配套理论讲解、perf 命令逐行解读与原始输出分析，全在站点 **https://geek-doc.cn**（「演示程序」栏目）。

## 目录总览

每个 demo 的**完整理论讲解**都对应站点里的专属文档页，地址格式 `https://geek-doc.cn/demos/<demo>/`：

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
| E1 | [echo](echo/) | 百万 QPS TCP 高并发实战（8 阶段 × 30 天） | 见 [echo/REPRO.md](echo/REPRO.md) |

> 💡 记不住地址？站点首页 **https://geek-doc.cn** → 顶部导航「演示程序」→ 每个 demo 都有对应页面，含复现命令、代码讲解与实测数据。

## 文档内嵌实验归档（experiments/）

站点理论文档中出现的**内嵌实验**（代码写在讲解页里、不在 demos/ 下），代码与实测数据统一归档于此，随新实验持续补充：

| 实验 | 主题 | 来源文档（站点） | 运行 |
|------|------|------------------|------|
| [numa-access](experiments/numa-access/) | 跨 NUMA 节点内存访问开销（本地 vs 远程 ~3x） | `concepts/cpu/numa-optimization.md` | `make -C experiments/numa-access run` |
| [busy-wait-vs-sleep](experiments/busy-wait-vs-sleep/) | 忙等待 vs 睡眠调度延迟/CPU 对比 | `concepts/latency/low-latency-patterns.md` | `make -C experiments/busy-wait-vs-sleep run` |

## 常用命令

```bash
make -C <demo>            # 编译（默认 -O0 -g，保留 perf 符号）
make -C <demo> run        # 编译并运行
make -C <demo> release    # 以 -O2 编译对比（观察优化器效果）
make -C <demo> clean      # 清理
```

## 配套理论文档

这里只提供**可运行代码**；每个实验背后的原理、`perf` 工具用法、原始输出与逐行分析，请到配套文档站阅读：

- **站点首页**：https://geek-doc.cn
- **演示程序栏目**：https://geek-doc.cn/demos/
- 站内搜索「性能剖析」「perf」即可直达对应理论章节

> 为什么"跑"和"读"分开？因为**代码就该能跑，原理就该讲透**——在站点读完理论，回这里 `make run` 亲手验证，效果最好。

## 许可

[MIT](LICENSE) — 自由使用、修改、再分发，仅需保留版权声明。

---

**站点**：https://geek-doc.cn · 喜欢这个仓库的话，欢迎在 GitHub 点个 ⭐
