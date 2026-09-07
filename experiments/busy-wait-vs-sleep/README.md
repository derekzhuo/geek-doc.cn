# 忙等待 vs 睡眠调度（busy-wait-vs-sleep）

对比两种线程同步等待模型的延迟与 CPU 开销：自旋忙等待 vs mutex + condition_variable 睡眠调度。

- **来源文档**：站点 `concepts/latency/low-latency-patterns.md`（忙等待 vs 睡眠调度）
- **依赖**：C++11 + pthread（仅需编译线程库）

## 复现

```bash
make            # 编译（-O2 -g -pthread）
make run        # 运行，ITERATIONS=1000000 次同步
```

## 实测数据（见 results.txt）

| 模型 | 总时间(us) | 单次延迟(us) | CPU使用率(%) |
|------|------------|---------------|--------------|
| 忙等待 | 1245 | 1.245 | ~100 |
| 睡眠调度 | 8920 | 8.92 | ~10 |

结论：忙等待延迟极低但吃满 CPU，适合短等待；睡眠调度延迟高但省 CPU，适合长等待。临界点约在等待时间超过上下文切换开销（1~10us）时。
