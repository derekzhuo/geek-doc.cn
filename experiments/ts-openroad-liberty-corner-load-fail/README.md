# OpenROAD read_liberty 多 corner 加载：未定义场景、重复库与映射接反

**对应教程**：https://geek-doc.cn/eda/ts-openroad-liberty-corner-load-fail.html（上线后生效）

## 复现方式

准备包含 OpenROAD 26Q4 的本地 Docker 镜像 `geek-eda:0.5-asic`，在本目录执行：

```bash
bash run.sh
```

实验用同一个单反相器网表和两份最小 Liberty 库。`ss.lib` 的 `cell_rise/cell_fall` 都是 0.10ns，`ff.lib` 都是 0.01ns，除库名与延迟外结构相同；`report_checks -scenes <名称>` 可以分别读出两个场景的实际单元延迟。

五段对照：

1. `bad-undefined.tcl`：没有 `define_corners` 就直接 `read_liberty -corner ss ss.lib`，报 `[ERROR STA-0102] ss is not the name of a scene.`，退出码 1。
2. `bad-duplicate-same.tcl`：把 `ff.lib` 两次读入 `ss`，得到 `[WARNING STA-1140] ... library tiny_ff already exists.`，`get_lib_cells */invx1` 返回两个同名条目，退出码仍为 0。
3. `bad-duplicate.tcl`：把 `ff.lib`、`ss.lib` 都读入 `ss`，没有报错或警告，`tiny_ff/invx1` 与 `tiny_ss/invx1` 同时存在，退出码 0。
4. `good.tcl`：先定义 `ss ff`，再分别加载对应库。`ss` 场景反相器延迟 0.1000ns，`ff` 为 0.0100ns，退出码 0。
5. `swapped.tcl`：故意把两份库接反。解析和链接仍成功、退出码 0，但 `ss` 变成 0.0100ns、`ff` 变成 0.1000ns，说明工具不能根据文件名判断工艺角语义。

当前版本的报错文字使用 scene（场景），`report_checks` 的报告字段仍显示 `Corner`。`-corner` 参数与 `-scenes` 报告参数按本版本实测使用。

## 文件

| 文件 | 作用 |
|---|---|
| `ff.lib` / `ss.lib` | 同一个 `invx1`，分别配置 0.01ns / 0.10ns 单元延迟 |
| `top.v` | 单实例顶层：一个 `invx1` |
| `tech.lef` / `macro.lef` | 最小工艺与宏 LEF，供链接设计和路径报告使用 |
| `bad-undefined.tcl` | 未定义场景硬失败 |
| `bad-duplicate-same.tcl` | 同一库文件重复加载及单元集合探针 |
| `bad-duplicate.tcl` | 两份不同库加载进同一场景及单元集合探针 |
| `good.tcl` / `swapped.tcl` | 正确映射与接反映射的双场景延迟对照 |
| `run.sh` | 串联五段实验并打印每次退出码 |
