# tlb-thrashing — 复现手册

> TLB 页表缓存抖动实验

## 构建与运行

```bash
cd tlb-thrashing
make          # 编译（默认 -O0 -g，保留 perf 符号与行号）
make run       # 运行实验
make clean    # 清理
```

## 运行要求

Linux x86-64

## 配套理论

实验原理、perf 命令解读与原始输出分析见主站点对应文档。

> 一句话：TLB 页表缓存抖动实验，clone 下来 `make` 即跑。
