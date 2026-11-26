# 四链接器全量/增量链接对照：ld.bfd / gold / lld / mold（cpp-linker-mold-lld-gold-benchmark）

**对应教程**：<https://geek-doc.cn/concepts/cpp-perf/cpp-linker-mold-lld-gold-benchmark.html>

同一批由生成器产出的翻译单元（TU），对象文件只编译一次，分别用
`-fuse-ld=bfd|gold|lld|mold` 链接，对照全量链接、单 TU 增量链接的耗时中位数
与二进制体积。四个二进制运行输出完全一致（checksum + hash 双校验）。

- **依赖**：g++（实测 13.3.0）、GNU binutils（ld.bfd 2.42 / gold 1.16）、lld 18、mold 2.30；仅标准库
- **结构**：`gen_tus.sh` 生成 N 个 TU（每个含跨 TU 函数调用与模板实例化，制造真实重定位项）+ 汇总 `main.cpp`；`sumparts.cpp` 定义被所有 TU 引用的非 inline 函数；`work.hpp` 放模板与声明
- **环境说明**：实测在 Docker 容器（Ubuntu 24.04，12 vCPU）内完成，工程目录经挂载卷访问。计时包含构建工具、进程启动与文件访问，结论的适用边界见教程正文

## 设计要点

本实验比较符号解析、重定位处理与输出段合并等完整链接工作，不拆分内部阶段。
纯空工程难以提供足够的符号与重定位输入，因此每个 TU 都带模板实例化和跨 TU
引用。全量链接每轮先删二进制强制重链；增量链接每轮只改 `tu0000.cpp`
一个常量、重编该 TU 后重链，重编译与重链分别计时。同一轮次会运行四份产物并
比较完整 checksum + hash 输出。每次运行先删除旧源码和产物，独立生成指定数量
的 TU，再进入 Make 计算对象列表；日志中的对象数断言防止规模切换后旧文件残留。
测量未清页缓存、未随机化执行顺序、无 IO 指标，因此不对首轮或缓存状态作因果判断。

## 复现

```bash
bash run.sh                 # 默认 NTU=300，全量 7 轮、增量 5 轮，结果写 results.txt
NTU=1000 bash run.sh        # 1000 个生成 TU，实际链接 1002 个对象文件
NTU=300 bash run.sh         # 从 1000 反向切回 300，验证旧 TU 不残留
```

单链接器手工构建：

```bash
make clean
bash gen_tus.sh 300 src     # 必须在 Make 解析对象列表前独立生成源码
make objects NTU=300        # 编译全部 .o
make build/bin/bench-mold NTU=300   # 或 bench-bfd / bench-gold / bench-lld
./build/bin/bench-mold      # 打印 checksum 与 hash，四者应完全一致
```

## 实测摘要（2026-11-26，容器内 UTC，i7-9750H / 12 vCPU）

| 指标（中位数） | ld.bfd | gold | lld | mold |
|---|---:|---:|---:|---:|
| 全量链接 302 个对象文件（ms） | 612 | 224 | 302 | 325 |
| 增量重链 302 个对象文件（ms） | 541 | 177 | 247 | 292 |
| 全量链接 1002 个对象文件（ms） | 1891 | 802 | 935 | 1138 |
| 增量重链 1002 个对象文件（ms） | 1754 | 671 | 784 | 997 |
| 二进制体积 302 个对象文件（字节） | 155048 | 155120 | 148760 | 177496 |

mold 在本次两个规模点均未超过 gold 和 lld；这只是当前版本、负载与容器路径下
的结果，不能外推为其他工程形态下的通用排名。完整逐轮样本与增量运行核对见
`results.txt`（300 个生成 TU）及教程中的 1000 个生成 TU 记录。
