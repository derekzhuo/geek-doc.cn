# RVO/NRVO、移动语义与 noexcept：vector 扩容为什么有时偷偷拷贝

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-rvo-nrvo-move-noexcept.html （随站点发布生效）

用一个带全局动作计数器的堆缓冲对象，把返回值优化、具名返回值优化与 `vector` 扩容时的
隐式拷贝/移动变成可读数字，并以 `-fno-elide-constructors` 反证复制消除的边界。

## 目录结构

| 文件 | 作用 |
|---|---|
| `widgets.hpp` | `SafeWidget`（移动 noexcept）与 `RiskyWidget`（移动无 noexcept）、全局计数器 |
| `widgets.cpp` | 独立翻译单元里的 RVO / NRVO 工厂（`noinline`） |
| `main.cpp` | RVO/NRVO 计数、N=20 扩容轨迹、N=20 万扩容计时三类场景 |
| `Makefile` | `bin/bench` 与 `bin/bench-no-elide`（反证构建）两个目标 |
| `run.sh` | 7 次计时取中位，并输出反证构建的 RVO/NRVO 计数对照 |
| `results.txt` | 一次完整运行的实测输出 |

两个 Widget 类函数体逐行相同，唯一差异是移动构造/赋值是否带 `noexcept`。
每个对象持有 256 字节堆缓冲：拷贝要重新分配并复制，移动只偷指针，
因此扩容选错机制的代价会被放大到可测量。

## 复现方式

```bash
make
bash run.sh
```

## 实测结果（Apple clang 21.0.0，-O2，macOS，2026-11-11）

| 场景 | 结果 |
|---|---|
| RVO（纯右值返回） | 仅 1 次参数构造，拷贝 0、移动 0；`-fno-elide` 下仍为 0（C++17 保证复制消除） |
| NRVO（具名局部返回） | 默认下仅 1 次参数构造；`-fno-elide` 下退化为 1 次移动 |
| SafeWidget 扩容 20 万次 | 拷贝 0、移动 462143，耗时中位 27.286 ms |
| RiskyWidget 扩容 20 万次 | 拷贝 262143、移动 200000，耗时中位 103.767 ms（约 3.8 倍） |

`type_traits` 证据：`is_nothrow_move_constructible<SafeWidget>` 为 1、
`RiskyWidget` 为 0。`vector` 扩容借 `std::move_if_noexcept` 维持强异常保证：
移动可能抛异常时，宁可逐元素拷贝。
