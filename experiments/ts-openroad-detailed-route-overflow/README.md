# OpenROAD detailed_route：残留 DRC、迭代预算与布线层排查

**对应教程**：https://geek-doc.cn/eda/ts-openroad-detailed-route-overflow.html（上线后生效）

## 复现方式

准备包含 OpenROAD 26Q4 的本地 Docker 镜像 `geek-eda:0.5-asic`，在本目录执行：

```bash
bash run.sh
```

实验使用同一个四级移位寄存器、同一份最小 LEF/Liberty 和同一布局。三档脚本只在详细布线迭代上限或可用信号层上变化：

1. `bad.tcl` 允许 metal1–metal3，但设 `-droute_end_iter 2`。日志依次报告 13、4、4 个违例，随后正常打印 `Complete detail routing`，退出码为 0；`bad-iter.drc.rpt` 实际含 4 条 `Metal Spacing`，因此退出码不能代替 DRC 验收。
2. `bad-layer.tcl` 保持 10 轮预算，只把信号层限制为 metal1。全局布线反复出现 `GRT-0299`，最终以 `GRT-0115` 表明仍有拥塞；详细布线入口对四个 `DFF_P/C` 分别报 `DRT-0073 No access point`，退出码为 1，尚未进入逐轮 DRC 优化。
3. `good.tcl` 恢复 metal1–metal3，允许 10 轮。违例从第 0 轮的 13 降到第 1、2 轮的 4，再在 guides-tiles 轮降到 0，退出码为 0，`good.drc.rpt` 为空。

当前版本输出为 `Number of violations = N`，并非旧资料中的固定措辞 `Number of violations remaining`。排查时应读取本次日志和 DRC 报告，不要只匹配某一句旧文案。

## 文件

| 文件 | 作用 |
|---|---|
| `top.v` | 四级移位寄存器，共 6 条待布信号网 |
| `tech.lef` | metal1–metal3、两层 CUT 与默认 via 的最小工艺 |
| `stdcell.lef` | `DFF_P` 与 `BUF_X1` 物理宏，PIN 位于 metal1 |
| `cts.lib` | 与物理宏配套的最小时序库 |
| `route.tcl` | 三档共用的布局、全局布线和详细布线流程 |
| `bad.tcl` | 三层资源，但详细布线限制 2 轮 |
| `bad-layer.tcl` | 只允许 metal1，复现拥塞与 pin access 失败 |
| `good.tcl` | 三层资源与 10 轮预算，复跑到零违例 |
| `run.sh` | 串联三档并打印退出码和 DRC 条目数 |

运行后生成的 `*.guide` 与 `*.drc.rpt` 是本地结果文件，不需要纳入版本控制。
