# minor/major 缺页单次成本对照基准

**对应教程**：https://geek-doc.cn/concepts/process/linux-page-fault-minor-major-cost.html （随站点发布生效）

同一 200 MiB 工作集下对照五种缺页场景的单次成本，用 `getrusage` 计 minor/major
缺页数、`CLOCK_MONOTONIC` 计耗时：

| 配置 | 含义 | 预期缺页类型 |
|---|---|---|
| `anon_cold` | 匿名 mmap 首次触碰 | 全部 minor fault |
| `anon_refault` | 触碰后 `MADV_DONTNEED` 归还再触碰 | 重新 minor fault |
| `anon_prefault` | 先预热，计时段为第二次触碰 | 零缺页（prefault 收益基线） |
| `file_cold` | `drop_caches` 后文件页首次触碰 | major fault，从磁盘读入 |
| `file_warm` | 页缓存热、新建映射首次触碰 | 只有 minor fault |

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/pf_bench.c` | 五配置扫档、`getrusage` 缺页计数与逐页触碰负载 |
| `Makefile` | `-O2 -std=c11` 构建，产物在 `bin/`（不入库） |
| `run.sh` | 五进程取 ns_per_fault 中位，再用 `perf stat` 采代表配置 |
| `results.txt` | 最近一次 `run.sh` 的完整输出 |
| `datafile.bin` | 200 MiB 随机数据（运行时生成，不入库） |

## 复现方式

```bash
make            # 产出 bin/pf_bench
sudo bash run.sh   # drop_caches 与 perf 计数需要 root
# 单跑某个配置：
./bin/pf_bench anon_cold
sudo ./bin/pf_bench file_cold datafile.bin
```

## 测量口径与边界

- 指标 `ns_per_fault` 是触碰循环总耗时除以 `getrusage` 观测到的缺页次数，
  包含页表建立、零页分配或磁盘读入的完整内核路径，不是缺页处理函数的孤立耗时；
- 每个配置进程内重复 5 轮、外层再跑 5 个独立进程取中位，压调度噪声；
- `file_cold` 每轮之间 `echo 3 > /proc/sys/vm/drop_caches`，云硬盘的
  major fault 延迟绑定该磁盘类型与虚拟化存储，不要与裸机 NVMe 横比；
- 测试机为 1 物理核 2 SMT 线程的云主机，单线程顺序触碰，未测并发缺页冲击。
