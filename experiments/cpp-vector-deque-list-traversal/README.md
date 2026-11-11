# vector / deque / list 遍历与插删成本基准

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-vector-deque-list-traversal.html （随站点发布生效）

在 100 万个 int 的相同元素量下，对照 `std::vector`、`std::deque`、`std::list` 三种容器的：

1. 顺序遍历耗时（range-for 求和）；
2. 头部插入 1000 次（`insert(begin(), ...)`）；
3. 中间位置（N/2）插入与删除各 1000 次；
4. 存活期堆占用：重载全局 `operator new`/`operator delete`，按 `malloc_size` 实际块大小统计每元素字节数与分配次数；
5. `/usr/bin/time -l` 单容器模式下的最大驻留内存、缺页与上下文切换。

## 复现方式

```bash
make            # 产出 bin/bench-O2 与 bin/bench-O0
bash run.sh     # O2/O0 各 7 次取中位，结果写入 results.txt
```

单容器运行（供 time 取内存证据）：

```bash
/usr/bin/time -l ./bin/bench-O2 vector   # 或 deque / list
```

## 文件说明

- `main.cpp`：基准主体，`run_container<Container>()` 模板对三容器跑同一套五段测量；
- `Makefile`：`-std=c++17 -Wall -Wextra`，O2/O0 双目标；
- `run.sh`：7 轮中位聚合与 `/usr/bin/time -l` 证据编排；
- `results.txt`：本机实测输出（Apple clang 21 / macOS 26），其他平台数值需重新实测，不要直接引用。
