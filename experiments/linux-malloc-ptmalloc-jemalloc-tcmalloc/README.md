# ptmalloc、jemalloc、tcmalloc 多线程争用实测

**对应教程**：https://geek-doc.cn/concepts/process/linux-malloc-ptmalloc-jemalloc-tcmalloc.html （随站点发布生效）

在 2 vCPU 云主机上用同一个多线程 malloc/free 基准对照三个分配器：glibc 自带
ptmalloc（无 LD_PRELOAD）、jemalloc、tcmalloc_minimal。每个工作线程维护
4096 个存活分配的稳态工作集，按 6:3:1 混合申请 64 B / 1 KiB / 16 KiB 对象，
循环做「申请→触写→随机替换释放」，线程数扫 1/2/4，每组合三轮；
另对 4 线程档跑 `perf stat` 采上下文切换与缺页旁证。

## 目录结构

| 文件 | 作用 |
|---|---|
| `alloc_bench.c` | 多线程分配器基准：稳态 ring 工作集 + 单点延迟采样，输出 p50/p99/p999 |
| `Makefile` | 编译 alloc_bench（-pthread） |
| `run.sh` | 三分配器 × 三线程档 × 三轮矩阵 + perf stat 争用旁证，产 summary.csv |
| `results/` | 完整运行日志、汇总 CSV 与 perf 输出 |

## 复现方式

```bash
sudo apt-get install -y libjemalloc-dev libgoogle-perftools-dev libtcmalloc-minimal4 \
                        linux-tools-common linux-tools-$(uname -r)
make
sudo -E bash run.sh
# 想快速冒烟：ITERS=200000 ROUNDS=1 sudo -E bash run.sh
```

分配器切换只靠 `LD_PRELOAD`，脚本启动时用 `ldd` 验证预加载确实生效，
glibc 档不预加载任何外部 malloc。

## 测量口径

- 总吞吐按全进程墙钟时间算（pthread_join 之后取数），不是各线程自报时间相加；
- 单点延迟只采前 2 万次申请的 malloc 耗时，所有线程样本合并排序后取分位；
- 三个分配器跑的是同一份二进制、同一固定随机种子序列，申请流逐位一致；
- 4 线程相对 2 vCPU 是两倍超额订阅，刻意制造争用，观察的正是这一段差异。
