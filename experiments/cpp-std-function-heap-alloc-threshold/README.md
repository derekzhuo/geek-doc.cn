# std::function 小对象缓冲阈值实测

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-std-function-heap-alloc-threshold.html （随站点发布生效）

重载全局 `operator new`（含对齐版）统计每次 `std::function` 构造的堆分配，
逐级增大捕获体，把小对象缓冲（SBO）的容量边界从「实现细节」变成可复现的数字，
并用过对齐类型与非 `noexcept` 移动类型做两个机制反证。

## 目录结构

| 文件 | 作用 |
|---|---|
| `main.cpp` | 尺寸扫档探针（1/8/16/20/24/32/40/48/64 字节）、过对齐与非 noexcept 移动两个反证、函数指针基线；重载普通版与对齐版 operator new/delete |
| `Makefile` | 同一份源码产出 `bin/bench-O2` 与 `bin/bench-O0` 两个二进制 |
| `run.sh` | 两档位各跑 7 次取构造/调用耗时中位，附 nm/otool 二进制证据 |
| `results.txt` | 一次完整运行的实测输出 |

## 复现方式

```bash
make
bash run.sh
```

## 实测结果（Apple clang 21.0.0，libc++ 13000，macOS，2026-11-11）

- 可调用体不超过 24 字节时构造零堆分配（SBO），28 字节起每次构造一次 `operator new`；
  本平台 libc++ 的小对象缓冲为 3 个指针宽（24 字节）。
- 过对齐类型（16 字节载荷、64 字节对齐）即使体积小也走堆，调用的是对齐版
  `operator new(size_t, align_val_t)`，单次块 128 字节。
- 移动构造在所有档位都不产生新分配：SBO 形态搬运缓冲，堆形态只偷指针。
- 非 `noexcept` 移动的小类型在本平台仍走 SBO——缓冲准入不看移动是否 noexcept，
  标准未规定 SBO 实现，不同标准库行为可以不同。
- `-O0` 下构造/析构中位：SBO 组约 99–110 ns，堆组约 218–231 ns（约 2.2 倍），
  过对齐约 391 ns（约 3.9 倍）；`-O2` 下全部收敛到 1.3–2.6 ns，差异被内联抹平。
- 调用成本与 SBO/堆无关，两档位各探针全程持平（O2 约 1.4–1.7 ns/次），
  两种形态都经同一条间接调用路径。
