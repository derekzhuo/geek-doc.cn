# 页缓存命中率怎样实测：mincore + fio 的冷热读对照实验

**对应教程**：https://geek-doc.cn/concepts/storage/linux-page-cache-hit-ratio-measure.html （随站点发布生效）

在 2 vCPU / 8 GiB 云主机上对同一个 512 MiB 数据集做四类读：drop_caches 后的
冷顺序读、紧接着的热顺序读、全驻留下的缓冲随机读、O_DIRECT 随机读，
每类三轮。用自写的 mincore(2) 小工具在每个用例前后采样文件页驻留率，
配合 /proc/diskstats 与 /proc/meminfo 判断真实磁盘流量，而不是凭直觉假设
「走了缓冲 I/O 就一定命中缓存」。

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/mincore_check.c` | mmap 文件后用 mincore(2) 统计驻留页比例 |
| `Makefile` | 编译 `mincore_check` |
| `read.fio` | fio 作业文件，rw/direct/iodepth/runtime 全部由环境变量注入 |
| `run.sh` | 三轮 × 四用例，逐用例记录 meminfo、diskstats、驻留率与 fio JSON |
| `results/*.json` | 12 份 fio 原始 JSON（冷/热顺序、缓冲/direct 随机各三轮） |
| `results/mincore.log` | 全部用例前后的驻留率采样 |
| `results/rerun2-run.log` | 完整运行记录（含 diskstats 与 meminfo） |
| `results/summary.csv` | 四用例三轮中位数/区间汇总 |

## 复现方式

```bash
make
# 需要 echo 3 > /proc/sys/vm/drop_caches 的权限
sudo -E bash run.sh
```

## 关键结果（本机实测）

| 用例 | IOPS 中位数（三轮区间） | 带宽 | clat p99 |
|---|---|---|---|
| 冷顺序读 | 49017（48962–49109） | 191.5 MiB/s | 0.6 µs |
| 热顺序读（mincore 100% 驻留） | 41571（41426–41650） | 162.4 MiB/s | 0.61 µs |
| 缓冲随机读（驻留衰减到 40–65%） | 3370（3310–6857） | 13.2 MiB/s | 3.85 ms |
| direct 随机读 | 6125（6119–6134） | 23.9 MiB/s | 2.54 ms |

两个反直觉但可解释的实测结论：

1. 热顺序读没有更快，反而略慢。diskstats 显示热读期间仍读出约一个文件大小的
   数据——内核预读在小内存虚拟机上发生抖动，旧页被新预读页挤走，缓冲路径还
   多一次页拷贝。
2. 缓冲随机读跑不过 O_DIRECT。随机读期间 mincore 驻留率从 100% 衰减到
   40–65%，大量请求未命中却仍支付页查找与回收成本；direct 路径绕开缓存，
   在 QoS 限速的云盘上反而稳定。

实验的真正交付物是测量方法：命中率必须用 mincore/diskstats 这类一手证据量化，
不能用「是否 buffered」代替。

## 测量口径

- 数据集用 O_DIRECT 预写，创建过程不污染页缓存；每轮先 drop_caches 归零；
- mincore 采样覆盖每个用例前后，驻留率变化与 diskstats 扇区读增量互相印证；
- fio 3.28 不支持命令行 `--VAR=value` 覆盖，统一走 `env VAR=... fio read.fio`。
