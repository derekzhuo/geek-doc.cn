# C++ 链接时优化三档对照：无 LTO / 全量 LTO / ThinLTO（cpp-lto-thin-full-benchmark）

**对应教程**：<https://geek-doc.cn/concepts/cpp-perf/cpp-lto-thin-full-benchmark.html>

同一组多翻译单元（TU）源码，分别用 `-O2`（无 LTO）、`-O2 -flto`（全量 LTO）、`-O2 -flto=thin`（ThinLTO）构建，对比构建耗时、二进制体积与运行耗时。

- **依赖**：支持 LTO 的 clang++（实测 Apple clang 21.0.0）或 g++；仅标准库，无第三方依赖
- **结构**：`main.cpp` 持有 8 个 `Worker` 派生对象的基类指针做间接调用；`sumparts.cpp` 定义跨 TU 的非 inline 小函数 `mix_step`；`worker0..7.cpp` 由 `gen_workers.sh` 生成，每个 TU 的热循环调用 2000 次 `mix_step`

## 设计要点

多 TU 是 LTO 发挥作用的前提：单 TU 程序在编译期就能完成内联，体现不出链接期优化的差异。热循环中各次 `mix_step` 调用互不携带依赖，无 LTO 时每次都是真实跨 TU call，LTO 内联后调用点可被展开并流水线化，差异因此被放大。三档构建的 `checksum` 完全一致，保证优化没有改变计算结果。

## 复现

```bash
make gen          # 生成 8 个 worker 翻译单元
bash run.sh       # 三档各干净重建 3 次（构建耗时取中位），每档预热 1 次后计时 7 次取中位
```

也可以单独构建某一档：

```bash
make bin/lto-none   # -O2，无 LTO
make bin/lto-full   # -O2 -flto
make bin/lto-thin   # -O2 -flto=thin
./bin/lto-thin
```

## 实测数据（Apple clang 21.0.0，macOS，见 results.txt）

| 构建档位 | 构建耗时中位 (ms) | 二进制体积 (B) | 运行耗时中位 (ms) |
|---|---|---|---|
| 无 LTO | 809 | 11816 | 51.206 |
| 全量 LTO (`-flto`) | 770 | 15472 | 19.229 |
| ThinLTO (`-flto=thin`) | 759 | 15544 | 19.072 |

结论：本例跨 TU 调用密集，LTO 两档运行耗时都降到无 LTO 的约 37%（约 2.7 倍提升），ThinLTO 与全量 LTO 运行表现几乎相同；10 个 TU 的小项目里三档构建耗时差异在测量噪声范围内，二进制体积反而因内联与展开增大约三成。工程上更大的 TU 规模才会显著体现全量 LTO 的链接变慢与 ThinLTO 的并行增量优势。不同批次运行的绝对数值随机器负载波动（同机多轮运行耗时中位落在 45–51 ms / 17–19 ms / 16–19 ms 区间），但三档相对差距稳定复现。
