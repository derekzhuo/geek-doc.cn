# 输入解析四路径吞吐基准（cpp-iostream-scanf-custom-parser）

**对应教程**：<https://geek-doc.cn/concepts/cpp-perf/cpp-iostream-scanf-custom-parser.html>（随站点发布生效）

在同一份 200 万行整数数据（20 MB，每行一个 int，含负数）上对比四条输入解析路径的吞吐：

- `scanf`：`fscanf(fp, "%d", &x)`，libc 格式化输入
- `cin-default`：`std::cin >> x`，保持 `sync_with_stdio(true)` 默认状态
- `cin-fast`：`sync_with_stdio(false)` + `tie(nullptr)` 后 `std::cin >> x`
- `custom`：`fread` 64KB 整块缓冲 + 手写带符号整数解析

## 复现

```bash
make            # 产出 bin/bench-O2 与 bin/bench-O0
bash run.sh     # 生成 data.txt，四组各 7 个独立进程取中位，结果写 results.txt
```

`results.txt` 包含 O2/O0 双档每组 7 轮原始行、跨进程中位汇总、checksum 一致性核验，
以及 `/usr/bin/time -l` 采集的驻留内存、次缺页与上下文切换。

## 补充探针

`probe.cpp` 把「读字节」与「格式化解析」拆开计时（ifstream 提取 / getline / 裸 fread / fscanf），
用于解释 std::cin 在 macOS + libc++ 上的耗时构成：

```bash
clang++ -O2 -std=c++17 probe.cpp -o probe-bin && ./probe-bin
```

实测输出见 `probe-results.txt`。

## 口径说明

- 计时用 `std::chrono::steady_clock`，每个进程只跑一轮，7 轮中位由 `run.sh` 跨进程聚合；
- 四组读同一文件、同一 LCG 数据集，checksum 必须全部一致；
- 数字来自 macOS + Apple clang + libc++ 平台，Linux + libstdc++ 上 `sync_with_stdio(false)`
  的收益与本平台不同，换平台需重新实测，不要直接沿用。
