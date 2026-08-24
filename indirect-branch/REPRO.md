# indirect-branch — 复现手册

> 间接分支预测（虚函数/函数指针/switch）

## 构建与运行

```bash
cd indirect-branch
make          # 编译（默认 -O0 -g，保留 perf 符号与行号）
make run       # 运行实验
make clean    # 清理
```

## 运行要求

Linux

## 配套理论

实验原理、perf 命令解读与原始输出分析见主站点对应文档。

> 一句话：间接分支预测（虚函数/函数指针/switch），clone 下来 `make` 即跑。
