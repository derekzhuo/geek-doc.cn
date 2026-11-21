# quartus-multicycle-path

**对应教程**：<https://geek-doc.cn/fpga/intermediate/quartus-multicycle-path.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 在 Cyclone IV E EP4CE6E22C8 上对同一条寄存器路径比较三档约束：普通单周期、仅放宽 setup、setup 与 hold 配套。实验重点不是追求更大的 setup slack，而是确认 hold 检查沿没有被错误地留在延后一拍的位置。

## 文件

- `pipeline.v`：`stage_reg` 到输出寄存器 `q` 的单时钟数据路径。
- `baseline.sdc`：20ns 时钟，不设多周期。
- `setup_only.sdc`：仅 `set_multicycle_path 2 -setup`。
- `paired.sdc`：setup 为 2，并补 `set_multicycle_path 1 -hold -end`。
- `compile.tcl`：一次编译，后续三档共用同一网表。
- `sta_*.tcl`：分别读取 SDC 并报告同一路径的 setup 与 hold。
- `run-quartus.ps1`：选择约束流程。
- 三份日志：对应三次 TimeQuest 运行的规范化输出。

## 复现（Windows，Quartus Prime Lite 25.1）

```powershell
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow baseline
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow setup_only
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow paired
```

工具路径在脚本顶部，按本机安装位置修改。若已删除编译数据库，同时删除旧的 `multicycle_demo.qsf` 后重跑即可重新编译。输出端口寄存器在网表中的单元名是 `q~reg0`，SDC 和报告命令必须引用该单元，而不是把端口 `q` 当成寄存器。

## 实测读数

| 约束 | setup latch edge | setup slack | hold latch edge | hold slack |
|---|---:|---:|---:|---:|
| 单周期 | 20ns | +19.038ns | 0ns | +0.500ns |
| 仅 setup=2 | 40ns | +39.038ns | 20ns | -19.520ns |
| setup=2 + hold=1 `-end` | 40ns | +39.038ns | 0ns | +0.500ns |

只写 setup 时，hold 报告会标出 `Multicycle - Setup End: 2`，却没有对应的 hold 多周期项；补 hold 后报告同时出现 `Multicycle - Setup End: 2` 和 `Multicycle - Hold End: 1`。三档保持同一网表，差异来自 SDC。

这里的正裕量只说明这条简化路径在给定器件和约束下的分析结果。多周期约束必须来自真实电路每两拍才更新或采样一次的数据协议，不能用约束把本来每拍变化的路径人为放宽。
