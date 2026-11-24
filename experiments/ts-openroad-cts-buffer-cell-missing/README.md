# OpenROAD clock_tree_synthesis 找不到 clock buffer：RSZ-0110 / CTS-0126 / CTS-0107

**对应教程**：https://geek-doc.cn/eda/ts-openroad-cts-buffer-cell-missing.html（上线后生效）

## 复现方式

准备包含 OpenROAD 26Q4 的本地 Docker 镜像 `geek-eda:0.5-asic`，在本目录执行：

```bash
bash run.sh
```

实验使用四个 `DFF_P` 组成的移位链，四个时钟输入接同一个 `clk`，寄存器之间有真实数据路径，因此修复后可以运行 `report_clock_skew`。`stdcell.lef` 同时提供 `BUF_X1` 与 `DFF_P` 的物理主单元；三份 Liberty 只在 buffer 数据上有目的地变化。

四档对照：

1. `bad-auto.tcl` 读取只有 `DFF_P` 的 `no_buf.lib`，不显式给 `-buf_list`。自动选择时报 `[ERROR RSZ-0110] No clock buffer candidates could be found from any libraries.`，退出码 1。
2. `bad-list.tcl` 读取完整库，却执行 `clock_tree_synthesis -buf_list NO_SUCH_BUF -root_buf NO_SUCH_BUF`。报 `[ERROR CTS-0126] No physical master cell found for buffer NO_SUCH_BUF.`，退出码 1。
3. `bad-slew.tcl` 使用有 `BUF_X1`、但输入 pin 没有 `max_transition` 的 `no_slew.lib`。候选与物理主单元检查已通过，随后报 `[ERROR CTS-0107] No max slew found for cell BUF_X1.`，退出码 1。
4. `good.tcl` 读取完整 `cts.lib`，显式使用 `-buf_list BUF_X1 -root_buf BUF_X1`。日志出现 4 sinks、Created 3 clock buffers、Created 3 clock nets、Path depth 2 - 2；探针输出 `PROBE buffers=3 instances=7`，退出码 0。对称树中 `report_clock_skew` 的 setup skew 为 0，source/target latency 数值绝对值均为 0.176395。

完整 buffer 的输入 pin 含 `max_transition : 0.5`，cell delay 与 transition 使用输入转换×输出负载的二维表。`good.tcl` 和 `bad-slew.tcl` 使用 `-apply_ndr none`，是为了让这个最小 LEF 实验只考察 buffer 条件，不把非默认布线规则作为变量；真实工程应按工艺规则配置 NDR，而不是照搬关闭。

当前版本未提供 `set_lib_cell_purpose` 命令；本实验使用本版真实可用的 `-buf_list` 与 `-root_buf` 接口。

## 文件

| 文件 | 作用 |
|---|---|
| `top.v` | 四级 `DFF_P` 移位链，四个 clock sink |
| `tech.lef` | 三层金属、SITE 与 RC 参数 |
| `stdcell.lef` | `BUF_X1`、`DFF_P` 的物理主单元 |
| `no_buf.lib` | 只有 `DFF_P`，用于复现 RSZ-0110 |
| `no_slew.lib` | 有 buffer 但缺输入 `max_transition`，用于复现 CTS-0107 |
| `cts.lib` | 完整 `BUF_X1` 与 `DFF_P` 时序模型 |
| `bad-auto.tcl` / `bad-list.tcl` / `bad-slew.tcl` | 三类失败 |
| `good.tcl` | 显式 buffer 修复、skew 报告与实例探针 |
| `run.sh` | 串联四档并打印退出码 |
