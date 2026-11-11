# placement new 固定块对象池基准

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-placement-new-object-pool.html （随站点发布生效）

用 placement new 实现的固定块对象池，把「内存分配」与「对象构造」解耦：池启动时只做
一次大块 `operator new` 拿到未构造存储，`alloc()` 用 placement new 在空闲槽位上构造对象，
`release()` 显式调析构并把槽位挂回侵入式 free list，内存块全程复用。与同类型对象的裸
`new`/`delete` 在百万次 create/destroy 场景下正面对打。

## 目录结构

| 文件 | 作用 |
|---|---|
| `main.cpp` | 对象池模板、可计数 Widget、重载 operator new/delete 计数、两个负载场景与耗尽演示 |
| `Makefile` | `-O2` / `-O0` 双目标，产物在 `bin/`（不入库） |
| `run.sh` | 两档各跑 7 次取中位，并用 `/usr/bin/time -l` 采 RSS、缺页与上下文切换 |
| `results.txt` | 最近一次 `run.sh` 的完整输出 |

## 复现方式

```bash
make            # 产出 bin/bench-O2 与 bin/bench-O0
bash run.sh     # 约半分钟，结果写入 results.txt
```

## 测量口径

- 场景一 churn：每次迭代 alloc 后立刻 release，最大存活数 1；
- 场景二 steady：保持 256 个存活对象，每迭代补一个销一个，模拟稳态轮换；
- 两个场景都对指针施加逃逸屏障（`asm volatile`），阻止编译器把不逃逸的 new/delete
  对优化成栈对象，否则裸 new 的堆分配会被整体消除、测到虚假的 1 ns/次；
- 分配次数由重载的全局 `operator new` 统计，构造/析构次数由 Widget 静态计数统计。
