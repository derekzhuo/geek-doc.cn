# C++ 剖面引导优化两阶段基准：baseline / 插桩训练 / PGO 重建（cpp-pgo-two-stage-benchmark）

**对应教程**：<https://geek-doc.cn/concepts/cpp-perf/cpp-pgo-two-stage-benchmark.html>

同一组分支密集型决策树源码，分别构建普通 `-O2` 版本（baseline）、`-fprofile-generate` 插桩版本（采集训练剖面）与 `-fprofile-use` 剖面引导版本（PGO），用两种评估负载对照 PGO 收益，并验证训练/评估分布错位时收益如何衰减。

- **依赖**：clang++ 与配套 `llvm-profdata`（实测 Apple clang 21.0.0，工具经 `xcrun` 自动探测）；仅标准库，无第三方依赖
- **结构**：`classifier.cpp` 是跨翻译单元的八级分支决策树，桶位空间 0..255；`main.cpp` 用确定性 LCG 产生 3000 万次输入，提供 `train`（偏斜分布，约 90% 落在热子树 192..229）、`matched`（与训练同分布）、`uniform`（0..255 均匀）三种负载

## 设计要点

PGO 的价值在于把运行期频次信息反馈给编译器：热分支被布成 fall-through 直通、冷路径挪到函数尾部，无剖面时编译器只能按源码顺序保守布局。`matched` 与训练同分布，量的是剖面贴合时的收益；`uniform` 与训练分布错位，量的是剖面失真后还剩多少收益。同一负载下 baseline 与 PGO 的 `checksum` 必须完全一致，证明优化只改布局不改结果。

热循环的键映射刻意只用 2 的幂运算（`seed & 255`、`192 + (seed & 31)`）。实测中发现 Apple clang 21.0.0 的 PGO 代码生成对热循环里的非常数取模（如 `% 100`、`% 38`）会退化为硬件 `divl` 指令，而 baseline 同一位置是 magic 乘法；`divl` 在 x86-64 上是十几到几十个周期的长指令，足以吞掉布局收益甚至让 PGO 更慢。排查过程与反汇编证据见教程正文，规避方法就是热路径改用位掩码映射。

## 复现

```bash
bash run.sh        # 插桩 → 训练 → llvm-profdata merge → PGO 重建 → 两负载各预热 1 次、计时 7 次取中位
```

也可以分阶段手动执行：

```bash
make bin/baseline bin/instrumented   # 普通版与插桩版
./bin/instrumented train             # 跑训练负载，产 default_*.profraw
xcrun llvm-profdata merge -output=pgo.profdata default_*.profraw
make bin/pgo                         # 读取 pgo.profdata 做剖面引导重建
./bin/pgo matched
./bin/pgo uniform
```

## 实测数据（Apple clang 21.0.0，macOS，见 results.txt）

| 评估负载 | baseline 中位 (ms) | PGO 中位 (ms) | 加速比 | checksum |
|---|---|---|---|---|
| matched（与训练同分布） | 96.261 | 66.322 | 约 1.45 倍 | 261562504（两版一致） |
| uniform（均匀，分布错位） | 85.784 | 77.867 | 约 1.10 倍 | 146953187（两版一致） |

两版二进制体积均为 8592 B，PGO 在本例只调整基本块布局与分支方向，没有明显的代码膨胀。结论：剖面与真实流量贴合时，分支密集代码可获得约 45% 的稳定收益；训练/评估分布错位后收益降到约 10%，但不会变成负收益——决策树前几级的大方向仍被正确引导。绝对数值随机器负载波动，同机多轮 matched 加速比稳定在 1.43–1.47 倍区间。上线 PGO 的前提是训练负载可长期代表生产流量，否则需要定期重采剖面。
