# 开寻址哈希表（线性探测）vs std::unordered_map 负载因子扫档

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-open-addressing-hash-table.html （随站点发布生效）

手写一张开寻址哈希表（线性探测 + backward-shift 删除，2 的幂容量、乘法散列），
与 libc++ 的 `std::unordered_map`（开链）在负载因子 0.3 到 0.9 共七档下对照：

- 成功 / 不成功查找的平均探测长度（仅开寻址表可直接统计）
- 成功查找、不成功查找、插入的每操作耗时（程序内 3 次取最短，脚本外层 7 次取中位）
- 每条目实际内存字节（开寻址按槽位实测，unordered_map 用重载 operator new 计存活堆字节）

## 复现方式

```bash
make            # 产出 bin/bench-O2 与 bin/bench-O0
bash run.sh     # 两档各跑 7 次取中位，结果写入 results.txt
```

macOS / Apple clang 21.0.0 / libc++ 13000 上实测约两分钟。换平台或换标准库后请重新跑，
不要直接沿用 results.txt 里的数字。

## 文件说明

- `main.cpp`：开寻址表实现、backward-shift 删除正确性自检、七档扫档与计时
- `Makefile`：`-std=c++17 -Wall -Wextra`，O2/O0 双目标
- `run.sh`：7 轮中位编排，输出 `results.txt`
