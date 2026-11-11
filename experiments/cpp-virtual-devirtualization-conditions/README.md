# 虚函数去虚化条件基准：五种调用形态 × none/LTO/PGO 三档（cpp-virtual-devirtualization-conditions）

**对应教程**：<https://geek-doc.cn/concepts/cpp-perf/cpp-virtual-devirtualization-conditions.html>

同一组虚调用代码，构造五种编译器可观察信息量不同的调用形态，分别用普通 `-O2`（none）、`-O2 -flto`（LTO）、LTO 加剖面引导（PGO）三档构建，用计时与反汇编回答：什么条件下编译器才敢把虚调用去虚化（devirtualization）。

- **依赖**：clang++ 与配套 `llvm-profdata`（实测 Apple clang 21.0.0，工具经 `xcrun` 自动探测）；仅标准库，无第三方依赖
- **结构**：`types.hpp` 定义抽象基类 `Base`、`final` 类 `Derived` 与开放类 `OpenDerived`；`factory.cpp` 提供跨翻译单元工厂；`main.cpp` 每个形态独占一个 `noinline` 函数，便于按符号地址截取反汇编

## 五种调用形态

| 形态 | 代码要点 | 编译器掌握的类型信息 |
|---|---|---|
| `direct` | 局部对象直接调 `d.step()` | 静态分派，编译期已知，不经虚表 |
| `heap_open` | `new OpenDerived()` 后经 `Base*` 调 | 无 final，类型被指针擦除 |
| `heap_final` | `new Derived()`（`final` 类）后经 `Base*` 调 | 继承链封闭，理论可证虚表唯一 |
| `visible_local` | 局部 `OpenDerived d`，`Base* p = &d` | 构造点可见，动态类型可观察 |
| `cross_tu` | 另一个 TU 的工厂返回 `Base*` | 单 TU 编译完全不可见真实类型 |

## 复现

```bash
bash run.sh                # 三档构建 + 插桩训练 + 7 次计时取中位 + 反汇编证据采集
bash collect-evidence.sh   # 只重跑反汇编证据（要求三档二进制已存在）
```

反汇编统计按 `nm` 给出的符号地址区间做，而不是按符号标签 `sed` 截取：LTO 的 ICF（相同代码折叠）会把同构函数合并到同一地址、只保留一个标签，按标签统计会把别名函数误判成零间接调用。

## 实测数据（Apple clang 21.0.0，macOS，100M 次/形态，见 results.txt）

| 形态 | none (ms) | LTO (ms) | PGO (ms) |
|---|---:|---:|---:|
| direct | 13.974 | 1.740 | 13.953 |
| heap_open | 139.505 | 160.850 | 111.610 |
| heap_final | 139.457 | 167.611 | 111.585 |
| visible_local | 139.544 | 139.539 | 111.529 |
| cross_tu | 139.526 | 160.963 | 111.589 |

所有形态、所有档位 `checksum` 完全一致（1485977516193069047），语义等价。三个结论：

1. **none 档下四种虚调用形态都没被去虚化**，连 `final` 类与可见局部对象也保留间接调用；`final` 在 Apple clang 21 的 `-O2` 下不是充分条件，热循环每轮一次 `callq *0x10(%rcx)`。
2. **LTO 单独不去虚化**：它把 `cross_tu` 与 `heap_open` 经 ICF 折叠为同一函数体（`nm` 可见同地址别名），但函数体内部的间接调用原样保留；虚调用形态的耗时没有改善，`direct` 反而因 64 倍循环展开压到 1.7 ms。
3. **PGO 做的是猜测性去虚化**：热循环变成「加载虚表槽 → 与剖面记录的唯一目标 `OpenDerived::step` 比较 → 相等则直接执行内联函数体，不等才走间接调用冷兜底」。四个虚形态统一降到约 111 ms（约 1.25 倍），但静态反汇编里间接调用指令仍在（冷兜底），只数指令条数会漏掉这类优化，必须读热循环本身。

另一个反直觉点：`direct` 在 PGO 档回到 14 ms，因为剖面引导的展开启发式把该循环的展开因子从 LTO 的 64 倍降到 8 倍。PGO 优化的是剖面中的整体热点布局，并不保证每个函数都比纯 LTO 更快。
