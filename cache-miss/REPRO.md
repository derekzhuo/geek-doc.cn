# cache-miss — 复现手册

> 缓存未命中模式（顺序/随机/跨步）
>
> 📖 配套理论讲解见站点：[https://geek-doc.cn](https://geek-doc.cn) · 本实验页面：[https://geek-doc.cn/demos/cache-miss/](https://geek-doc.cn/demos/cache-miss/)

## 构建与运行

```bash
cd cache-miss
make          # 编译（默认 -O0 -g，保留 perf 符号与行号）
make run       # 运行实验
make clean    # 清理
```

## 运行要求

Linux

## 配套理论

实验原理、perf 命令解读与原始输出分析见配套站点对应文档：

- 站点首页：https://geek-doc.cn
- 本实验页面：https://geek-doc.cn/demos/cache-miss/

> 一句话：缓存未命中模式（顺序/随机/跨步），clone 下来 `make` 即跑。完整理论请回站点 https://geek-doc.cn 阅读。
