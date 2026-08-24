# SPSC / SPMC / MPSC / MPMC 消息队列基准（spsc-mpsc-queue）

对比 **SPSC 无锁环形队列**（零 CAS、零内存回收）与 **`std::queue` + `std::mutex`** 的吞吐，并给出四象限（SPSC/SPMC/MPSC/MPMC）性能量级参考。

- **来源文档**：站点 `concepts/latency/spsc-mpsc-queue.md`（消息队列四象限全景）
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
| SPSC 独立环 fan-out（SPMC 广播, 4 消费者） | ~90 | ~35 |
| MPSC 链表（4 生产者） | ~45 | ~90 |
| SPMC 共享队列 CAS 抢读（4 消费者） | ~22 | ~320 |
| `boost::lockfree::queue`（MPMC） | ~20 | ~380 |

结论：SPSC 让每个原子索引只有单方写入，做到"无锁、无 CAS、无回收"，比加锁快约 20 倍。SPMC 用"独立 SPSC 环广播"几乎不损失吞吐，用"共享队列 CAS 抢读"则明显下降——**拓扑越受限、分区隔离越多就越快**。完整原理、四象限对比与内存序分析见站点文档。
