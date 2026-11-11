# map / unordered_map / 排序 vector 查找性能对照基准

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-unordered-map-sorted-vector-lookup.html （随站点发布生效）

同一组随机 int key 下，对照三种查找结构在元素量 8 到 100 万扫档时的随机命中查找均摊耗时、构造/排序预处理耗时与每条目内存占用：

- `std::map<int,int>`：红黑树，O(log N) 指针追踪；
- `std::unordered_map<int,int>`：开链哈希表，均摊 O(1)；
- 排序后的 `std::vector<pair<int,int>>` + `std::lower_bound`：二分查找，O(log N) 次连续内存比较。

每档 10 万次随机命中查找，程序内部重复 3 轮取最短，`run.sh` 再让 O2/O0 两个二进制各跑 7 次按行标签取中位。构造期通过重载全局 `operator new`/`operator delete` 统计各结构的存活堆字节，换算每条目占用。

## 复现方式

```bash
make            # 产出 bin/bench-O2 与 bin/bench-O0
bash run.sh     # 两档各 7 轮，结果写入 results.txt
```

环境：Apple clang 21.0.0（clang-2100.1.1.101），macOS 26，libc++ 13000。换编译器、标准库或 CPU 微架构后绝对值与拐点位置需要重新实测，不要直接引用本目录的数字。

## 文件说明

- `main.cpp`：扫档基准与分配计数实现；
- `Makefile`：O2/O0 双目标；
- `run.sh`：7 轮中位编排与符号证据；
- `results.txt`：一次完整运行的归档输出。
