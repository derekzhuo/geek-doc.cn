# cpp-variant-vs-virtual-dispatch

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-variant-vs-virtual-dispatch.html （随站点发布生效）

同一组 shape 协议（`area` / `perimeter`，Circle、Square、Rectangle、Triangle 四个具体类型）的两种多态实现对照：

- 基类 + 虚函数：堆对象，`unique_ptr<VShape>` 数组，指针间接调用；
- `std::variant` + `std::visit` 泛型 lambda：值语义、栈上定长对象；
- `std::variant` + 手写 `get_if` 分派链：同一存储，不同访问方式。

## 测量内容

- 单态（全 Circle）与混合（4 类型轮转）两场景，各 1000 万次 `area + perimeter` 调用，O2/O0 双档各 7 轮取中位；
- `sizeof` 对照与构造 1 万个对象期间的 `operator new` 计数（重载全局 new/delete）；
- O2 反汇编：虚调用的 vtable 槽位间接 `callq`、visit 的 discriminant 索引函数表、get_if 的零 call 跳转表。

## 复现

```bash
make            # 产出 bin/bench-O2 与 bin/bench-O0
bash run.sh     # 7 轮中位 + nm/otool 证据，结果写入 results.txt
```

环境：macOS / Apple clang，`-std=c++17 -Wall -Wextra`。其他平台（libstdc++、Linux、不同架构）的耗时与跳转表形态需重新实测，不要直接引用本目录数字。
