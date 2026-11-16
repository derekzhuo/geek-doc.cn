# bpftrace 剖析 malloc 调用点：定位内存增长源头

**对应教程**：https://geek-doc.cn/concepts/perf/linux-bpftrace-malloc-stack-profiling.html （随站点发布生效）

用 bpftrace 的 uprobe 在一个含三个分配点（64 B 高频小块、4 KiB 低频大块、
256 B 中频会话对象）的示例程序的函数入口挂探针，按调用点聚合 malloc 的调用
次数与申请字节数，复现线上「内存只涨不跌、不知道谁在分配」的定位过程。

## 目录结构

| 文件 | 作用 |
|---|---|
| `malloc_hotspots.c` | 示例目标程序：三个形态不同的分配点，故意不释放 |
| `malloc-profile.bt` | bpftrace 脚本：三个业务函数入口 uprobe + libc malloc 总量探针，每 5 秒快照 |
| `run.sh` | 非 PIE 编译并渲染探针路径，bpftrace -c 模式跑完整流程 |
| `Makefile` | `-O2 -g -fno-omit-frame-pointer -fno-pie -no-pie` 编译选项 |
| `results/` | bpftrace 快照与最终聚合日志 |

## 复现方式

```bash
sudo apt-get install -y bpftrace bpfcc-tools
make
sudo -E bash run.sh
```

## 测量口径

- 三个分配函数带 `__attribute__((noinline))` 且以非 PIE 编译，bpftrace
  直接在函数入口挂 uprobe——探针位置即调用点，不依赖用户态栈帧回溯
  （Ubuntu 22.04 的 glibc 未带帧指针，`ustack` 穿不过 `malloc`）；
- 每个调用点分别 `count()` 与按固定块大小 `sum` 字节数，另在 libc `malloc`
  上挂一个总量探针，三组调用点之和 63600 次应与全进程 malloc 总量
  （实测 269779 次，差额为链接器/printf 等运行时内部分配）对照；
- 程序 24 轮、每轮间隔 600 ms，总运行约 15 秒，bpftrace 每 5 秒一次快照、
  退出时打印完整 map，`results/` 保留全部原始输出。
