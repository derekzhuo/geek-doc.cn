# tlb-thrashing — 复现手册

> TLB 页表缓存抖动实验
>
> 📖 配套理论讲解见站点：[https://geek-doc.cn](https://geek-doc.cn) · 本实验页面：[https://geek-doc.cn/demos/tlb-thrashing/](https://geek-doc.cn/demos/tlb-thrashing/)

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

实验原理、perf 命令解读与原始输出分析见配套站点对应文档：

- 站点首页：https://geek-doc.cn
- 本实验页面：https://geek-doc.cn/demos/tlb-thrashing/

> 一句话：TLB 页表缓存抖动实验，clone 下来 `make` 即跑。完整理论请回站点 https://geek-doc.cn 阅读。
