# vivado-vs-quartus-rtl-qor

**对应教程**：<https://geek-doc.cn/fpga/intermediate/vivado-vs-quartus-rtl-qor.html>（随对应教程上线后生效）

将完全相同的 16×8 同步 FIFO RTL 分别交给 Vivado 2017.4 与 Quartus Prime Lite 25.1 实现，输入时钟均约束为 100MHz。Vivado 器件为 Artix-7 `xc7a35ticsg324-1L`，Quartus 器件为 Cyclone IV E `EP4CE6E22C8`。实验比较资源报告的语义和内部寄存器路径，不把不同器件的单次结果解释为工具或 FPGA 的绝对性能排名。

## 复现（Windows）

```powershell
powershell -ExecutionPolicy Bypass -File run-cross.ps1
```

工具路径在脚本顶部，按本机安装位置修改。脚本依次完成 Vivado 综合、布局布线和时序分析，以及 Quartus 全编译和 TimeQuest setup/hold 检查；任一工具失败、缺少时序路径或出现负裕量都会中止。脚本只替换本实验的 `work/`、`results/` 与压缩包，不终止其他工具会话。

## 2026-11-22 实测结果

| 工具与器件 | 逻辑资源 | 寄存器 | 块存储 | Setup WNS | Hold WHS |
|---|---:|---:|---:|---:|---:|
| Vivado 2017.4 / Artix-7 `xc7a35ticsg324-1L` | 17 Slice LUT | 13 Slice Register | 1 RAMB18 | 6.665 ns | 0.119 ns |
| Quartus Prime Lite 25.1 / Cyclone IV E `EP4CE6E22C8` | 201 LE（139 个组合函数） | 149 | 0 bit | 3.536 ns | 0.186 ns |

两种实现均找到 setup/hold 路径且裕量为正。Quartus 分别检查 Slow 1200mV 85℃ 与 Fast 1200mV 0℃：setup/hold 分别为 3.536/0.453ns 和 7.180/0.186ns，表中取两角各自最差值。Quartus 原始编译日志给出资源差异的直接线索：它报告 10335，不识别 Vivado 的 `ram_style` 属性；276014/276007 随后指出 `mem` 因异步读逻辑没有推断成 RAM。因此，这里的 201 LE 与 149 个寄存器包含以逻辑实现的存储阵列，不能同 Vivado 的 17 LUT、13 寄存器加 1 块 RAM 做简单数量排名。

Vivado 的 Slice LUT 与 Quartus 的 LE 也不是等价单位。上述结果只对应这份 RTL、10 ns 内部时钟约束、指定器件和工具版本的单次实现；Quartus 报告明确提示未设置时钟不确定性，引脚也未分配，同时未设置输入输出延迟，因此这些数值不是板级时序签核，不用于比较板上接口时序、最高工作频率或工具优劣。

`results/` 保存最终一轮的 Vivado 日志、资源与时序报告，以及 Quartus 编译日志、map/fit summary 和 TimeQuest 日志。运行脚本会重建并替换该目录。
