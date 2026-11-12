# 自动向量化对照基准（循环形态、restrict、对齐与展开干预）

**对应教程**：https://geek-doc.cn/concepts/cpp-perf/cpp-autovectorization-pragmas-alignment.html（上线后生效）

用 9 组共 11 个测量函数回答一个问题：什么循环形态能被编译器自动向量化，什么形态会被挡住，`restrict`、对齐承诺与展开 pragma 各自改变了什么。

## 目录结构

- `src/g1_axpy_restrict.cpp` ~ `src/g9_unroll.cpp`：9 组循环，每组一个 `noinline` 函数
- `src/main.cpp`：计时驱动，N=262144、每轮 200 遍，输出 ns/pass 与 checksum
- `Makefile`：三档构建（`-O2` / `-O2 -fno-vectorize` 标量对照 / `-O2 -march=native`）+ 逐组 `-Rpass` 向量化报告
- `run.sh`：全流程编排，7 次测量取中位、算加速比、采反汇编证据，结果写 `results.txt`

## 复现方式

```bash
make run        # 等价于 make all && make reports && bash run.sh
```

约两分钟输出三档中位耗时、逐组向量化报告（含未向量化原因）与向量指令反汇编摘录。机器需为 clang（在 Apple clang 21 上开发）；GCC 用户把 `-Rpass=...` 换成 `-fopt-info-vec` 即可，报告语义相同。

## 测量口径

- 标量基线不是 O0，而是 `-O2 -fno-vectorize -fno-slp-vectorize`：同样的优化级别只关掉向量化，加速比才能干净归因。
- 计时不含输入初始化，setup 在计时区外执行。
- 结论只代表本机工具链与架构（x86-64、SSE2/AVX2），其他平台需重新实测。
