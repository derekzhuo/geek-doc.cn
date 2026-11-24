# OpenSTA 多 corner 漏读 Liberty：STA-1112 在 link_design 阶段失败

**对应教程**：https://geek-doc.cn/eda/ts-opensta-multicorner-lib-missing.html（上线后生效）

## 复现方式

准备包含 OpenROAD 26Q4 的本地 Docker 镜像 `geek-eda:0.5-asic`，在本目录执行：

```bash
bash run.sh
```

实验用同一个单反相器网表和三份最小 Liberty 库。`ss.lib`、`ff.lib`、`tt.lib` 的 `cell_rise/cell_fall` 分别为 0.10、0.01、0.05ns，输入转换与输出负载条件相同。

1. `bad.tcl` 声明 `ss ff tt`，只读取 `ss.lib` 与 `tt.lib`，故意漏掉 `ff.lib`。两次 LEF 读取成功后，`link_design top` 报 `[ERROR STA-1112] Liberty cell tiny_ss/invx1 for corner ff/min not found.`，退出码 1。脚本不能进入后面的逐场景 `report_checks`，因此本例的真实现象不是路径延迟显示 inf。
2. `good.tcl` 只补上 `read_liberty -corner ff ff.lib`，其余步骤不变。`ss`、`ff`、`tt` 的 `u_inv/z` Delay 和 data arrival time 分别为 0.1000、0.0100、0.0500ns，退出码 0。

错误行中的 `tiny_ss/invx1` 是已链接主单元名称，排查重点是其后的 `for corner ff/min`：缺少的是 `ff` 场景对应的 Liberty cell，不应据此误删正常的 `ss.lib`。

## 文件

| 文件 | 作用 |
|---|---|
| `ss.lib` / `ff.lib` / `tt.lib` | 同一 `invx1`，单元延迟分别 0.10 / 0.01 / 0.05ns |
| `top.v` | 单实例顶层 |
| `tech.lef` / `macro.lef` | 最小工艺与宏 LEF |
| `bad.tcl` | 声明三个场景但漏读 `ff` 库 |
| `good.tcl` | 补齐三库并逐场景报告路径 |
| `run.sh` | 串联失败与修复并打印退出码 |
