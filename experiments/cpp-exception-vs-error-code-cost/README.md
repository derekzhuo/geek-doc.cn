# 异常、错误码与 Expected：三种错误传递机制的路径级成本基准

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-exception-vs-error-code-cost.html （随站点发布生效）

同一个数字串解析函数，分别用 C++ 异常、传统错误码、Expected 风格返回值三种机制传递错误，
在「全部成功」和「全部失败」两条路径上分别计时，回答「零成本异常到底零的是哪部分成本」。

## 目录结构

| 文件 | 作用 |
|---|---|
| `logic.hpp` | 三机制函数声明与 `ExpectedInt`（同构最小替代，见下） |
| `logic.cpp` | 共享解析核心 `parseCore`，三种机制只在错误传递方式上有差异 |
| `main.cpp` | 六个 `noinline` runner（3 机制 × 2 路径），LCG 确定性生成 token |
| `Makefile` | `make` 构建 `bin/bench`（`-O2 -std=c++17 -Wall`） |
| `run.sh` | 干净重建后跑 7 次取六格中位，并采集人格符号、异常表段与热循环反汇编 |
| `results.txt` | 一次完整运行的实测输出（含证据段） |

## 为什么自带 ExpectedInt

本机工具链为 Apple clang 21.0.0，其 libc++ 未提供 C++23 标准库 `<expected>`。
`logic.hpp` 中的 `ExpectedInt { int value; int error; bool ok(); }` 与
`std::expected<int, int>` 的值/错误双载体形态同构：同样靠普通返回值通道传递、
调用方同样必须显式检查 `ok()`，因此成本结论可直接迁移到标准库实现。

## 复现方式

```bash
make
bash run.sh
```

成功路径每格 5000 万次调用，错误路径每格 200 万次（抛异常很慢，次数小一档）；
二进制内含预热，`run.sh` 跑 7 轮按格取耗时中位。

## 实测结果（Apple clang 21.0.0，-O2，macOS，2026-11-11）

| 机制 | 成功路径中位 (ms) | 错误路径中位 (ms) |
|---|---:|---:|
| exception | 268.518 | 11990.551 |
| errcode | 348.799 | 3.909 |
| expected | 278.769 | 3.621 |

成功路径三者同量级（错误码略慢来自分支形态差异，非异常机制开销）；
错误路径抛异常约 11990 ms 对 3.9 ms，慢约 3000 倍，折合单次抛接约 6 μs。
证据段同时给出 `___gxx_personality_v0` 未定义符号、`__gcc_except_tab` 异常表段，
以及成功路径热循环只有普通直接调用、无异常指令的反汇编。
