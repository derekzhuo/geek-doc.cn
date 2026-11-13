# 四链接器全量/增量链接对照：ld.bfd / gold / lld / mold（cpp-linker-mold-lld-gold-benchmark）

**对应教程**：<https://geek-doc.cn/concepts/cpp-perf/cpp-linker-mold-lld-gold-benchmark.html>

同一批由生成器产出的翻译单元（TU），对象文件只编译一次，分别用
`-fuse-ld=bfd|gold|lld|mold` 链接，对照全量链接、单 TU 增量链接的耗时中位数
与二进制体积。四个二进制运行输出完全一致（checksum + hash 双校验）。

- **依赖**：g++（实测 13.3.0）、GNU binutils（ld.bfd 2.42 / gold 1.16）、lld 18、mold 2.30；仅标准库
- **结构**：`gen_tus.sh` 生成 N 个 TU（每个含跨 TU 函数调用与模板实例化，制造真实重定位项）+ 汇总 `main.cpp`；`sumparts.cpp` 定义被所有 TU 引用的非 inline 函数；`work.hpp` 放模板与声明
- **环境说明**：实测在 Docker 容器（Ubuntu 24.04，12 vCPU）内完成，工程目录经挂载卷访问。挂载文件系统的元数据开销会计入链接耗时，小工程下并行型链接器的优势被稀释，结论的适用边界见教程正文

## 设计要点

链接器的差距主要来自符号解析、重定位处理与输出段合并的并行度。纯空工程链接
耗时里进程启动占比太高，区分不出链接器本身，因此每个 TU 都带模板实例化和
跨 TU 引用，302/1002 个对象文件提供足够的符号与重定位工作量。全量链接每轮
先删二进制强制重链；增量链接每轮只改 `tu0000.cpp` 一个常量、重编该 TU 后
重链，重编译与重链分别计时。首轮流式读盘的冷缓存离群值保留在原始样本里，
汇总取中位数避免被它带偏。

## 复现

```bash
bash run.sh                 # 默认 NTU=300，全量 7 轮、增量 5 轮，结果写 results.txt
NTU=1000 bash run.sh        # 大规模档，观察链接器差距随 TU 数的变化
```

单链接器手工构建：

```bash
make gen objects            # 生成 TU 并编译全部 .o
make build/bin/bench-mold   # 或 bench-bfd / bench-gold / bench-lld
./build/bin/bench-mold      # 打印 checksum 与 hash，四者应完全一致
```

## 实测摘要（2026-11-14，容器内 UTC，i7-9750H / 12 vCPU）

| 指标（中位数） | ld.bfd | gold | lld | mold |
|---|---:|---:|---:|---:|
| 全量链接 302 TU（ms） | 543 | 217 | 262 | 290 |
| 增量重链 302 TU（ms） | 518 | 192 | 231 | 277 |
| 全量链接 1002 TU（ms） | 1812 | 713 | 854 | 1054 |
| 二进制体积 302 TU（字节） | 155048 | 155120 | 148760 | 177496 |

mold 在这个挂载卷上的中小工程里没有跑出官方案例里的领先幅度：它的并行架构
在百万级符号、几十 MB 以上的大二进制上才摊薄得开固定开销。完整逐轮样本见
`results.txt`（300 TU）与教程附带的 1000 TU 运行记录。
