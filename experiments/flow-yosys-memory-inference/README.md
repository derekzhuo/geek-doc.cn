# flow-yosys-memory-inference

**对应教程**：https://geek-doc.cn/eda/flow-yosys-memory-inference.html

Yosys 存储器推断流程的最小对照实验：同一份 `rtl.v` 里放三种 16×8 数组写法，在 `hierarchy`、`proc`、`memory -nomap`、`memory_map` 四个断点分别 `stat`，观察存储器从前端数组到 `$mem_v2` 再到门级 DFF 的形态变化。

- `ram_sync`：同步写 + 同步读（输出寄存），带 `initial` 初值，标准 RAM 模板
- `ram_async`：同步写 + 异步读（`assign` 引出）
- `ram_flat`：组合 `always @(*)` 块里异步写，前端直接放弃推断

## 复现

需要本机有 Docker 镜像 `geek-eda:0.3-sta`（Yosys 0.33）：

```bash
sh run.sh
```

脚本会依次打印 `yosys -V`、`help memory`、`help synth_ice40` 中与 memory 相关的行，以及三个模块在四个断点的完整 `stat`。
