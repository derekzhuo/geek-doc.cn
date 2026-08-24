# compiler-reordering — 复现手册

> 编译器重排与 data-race UB

## 构建与运行

```bash
cd compiler-reordering
make          # 编译（默认 -O0 -g，保留 perf 符号与行号）
make run       # 运行实验
make clean    # 清理
```

## 运行要求

任意（演示用）

## 配套理论

实验原理、perf 命令解读与原始输出分析见主站点对应文档。

> 一句话：编译器重排与 data-race UB，clone 下来 `make` 即跑。
