# 跨 NUMA 节点内存访问开销（numa-access）

量化"本地节点 vs 远程节点"内存访问的延迟差距。

- **来源文档**：站点 `concepts/cpu/numa-optimization.md`（量化分析跨 NUMA 内存访问开销）
- **依赖**：`libnuma`（Debian/Ubuntu：`apt install libnuma-dev`）
- **运行前提**：多节点 NUMA 机器（`numactl --hardware` 能看到多个 node）

## 复现

```bash
make            # 编译（-O2 -g -lnuma）
make run        # 默认 node0 vs node1，64MB
# 自定义：./numa_access <本地节点> <远程节点> <字节数>
```

## 实测数据（见 results.txt）

```
本地访问时间: 1245us
远程访问时间: 3720us
开销比: 2.99x
```

结论：跨节点访问约 3 倍开销，NUMA 优化（绑核 + 内存本地化）可显著降低访问延迟。
