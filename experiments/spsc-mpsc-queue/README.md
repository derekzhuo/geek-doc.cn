# SPSC / MPSC 无锁消息队列基准（spsc-mpsc-queue）

对比 **SPSC 无锁环形队列**（零 CAS、零内存回收）与 **`std::queue` + `std::mutex`** 的吞吐。

- **来源文档**：站点 `concepts/latency/spsc-mpsc-queue.md`（SPSC/MPSC 消息队列）
- **依赖**：C++17 + pthread

## 复现

```bash
make            # 编译（-O2 -g -std=c++17 -pthread）
make run        # 运行（默认 1M 次 push/pop）
# 自定义：./spsc_bench <元素数>
```

## 实测数据（见 results.txt）

| 队列 | 吞吐 (M ops/s) | P99 延迟 (ns) |
|------|---------------|---------------|
| `std::queue` + `std::mutex`（SPSC） | ~5 | ~900 |
| **SPSC 无锁环形** | **~120** | **~25** |

结论：SPSC 让每个原子索引只有单方写入，做到"无锁、无 CAS、无回收"，比加锁快约 20 倍。完整原理、MPSC 接入方案与内存序分析见站点文档。
