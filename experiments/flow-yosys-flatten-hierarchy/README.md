# Yosys flatten 前后对照实验

**对应教程**：https://geek-doc.cn/eda/flow-yosys-flatten-hierarchy.html

两层参数化设计（`top` generate 例化 4 个 `sub` 累加器），在 Yosys 里对照
`flatten` 前后的 `stat` 读数、`write_verilog` 网表结构与按子模块名选择的行为，
并观察默认 `synth` 与 `synth -flatten` 流程中 flatten 出现的位置。

## 复现

```bash
make run
```

需要本机装有 docker 且有 `geek-eda:0.4-flow` 镜像（Yosys 0.33）。
脚本内每个小节独立调用一次 yosys，依次输出：

1. 保留 hierarchy 时的 `stat`（逐模块小节 + design hierarchy 汇总）；
2. 保留 hierarchy 时 `write_verilog` 的模块清单与例化行；
3. 按子模块名 `stat sub`；
4. `flatten` 后的 `stat`（只剩 top 一个模块）；
5. flatten 后网表的模块清单与层级路径线网名；
6. flatten 后再 `stat sub`（模块已删除）；
7. 默认 `synth` 中 hierarchy/flatten 相关日志；
8. `synth -flatten` 中 FLATTEN pass 的位置（3.3 节）。

`make clean` 删除生成的 `net_hier.v` / `net_flat.v`。

## 文件

| 文件 | 说明 |
|---|---|
| `sub.v` | 子模块：带使能、异步复位的 4 位累加器 |
| `top.v` | 顶层：generate 例化 4 个 sub |
| `run.sh` | 八段对照脚本，容器内执行 |
