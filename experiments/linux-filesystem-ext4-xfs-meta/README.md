# ext4 与 xfs 元数据性能对照：2 万小文件的创建、遍历与删除实测

**对应教程**：https://geek-doc.cn/concepts/storage/linux-filesystem-ext4-xfs-meta.html （随站点发布生效）

在同一台 2 vCPU / 8 GiB 云主机上，用同一物理盘上的两个等大 loop 设备分别建
ext4 与 xfs 文件系统，跑完全相同的小文件工作负载：100 个目录各 200 个
4 KiB 文件（共 2 万个），依次测量创建、遍历 stat、删除三阶段耗时，重复三轮，
每轮开始前 drop_caches 排除缓存差异。

## 目录结构

| 文件 | 作用 |
|---|---|
| `meta_bench.c` | 自写元数据基准：create/scan/delete 三模式，输出墙钟毫秒与 ops/s |
| `Makefile` | 编译 meta_bench |
| `run.sh` | 建双 loop 设备、mkfs、挂载、三轮对照，trap 自动清理 |
| `results/` | 完整运行日志与汇总 CSV |

## 复现方式

```bash
sudo apt-get install -y xfsprogs e2fsprogs   # 一般镜像已自带
make
sudo -E bash run.sh
```

loop 设备建在 `/var/tmp/meta-bench/`，默认两个 4 GiB 镜像；脚本退出时
自动卸载、detach loop 并删除镜像。`ROUNDS=5 bash run.sh` 可改轮次。

## 测量口径

- 两文件系统使用各自默认 mkfs 参数与默认挂载选项，只让「文件系统实现」这一个变量变化；
- 同一底层物理盘、同样 4 KiB 文件尺寸与目录布局，loop 开销对两者相同；
- 每阶段前后由基准程序自己打 `CLOCK_MONOTONIC` 时间戳，轮间 `drop_caches`；
- 遍历阶段对每个目录项做一次 `lstat`，统计的是 readdir + stat 的组合成本。
