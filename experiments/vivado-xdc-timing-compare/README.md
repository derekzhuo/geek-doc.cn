# vivado-xdc-timing-compare

**对应教程**：https://geek-doc.cn/fpga/intermediate/exp-vivado-xdc-constraints-template.html

同一份 RTL 在「宽松 100MHz」与「收紧 500MHz」两档 XDC 时钟约束下的实现与时序对照：直观看到 create_clock 周期如何决定 WNS/TNS 与布线结果。

## 内容

- `pipe.v`：16 轮 64 位 rotate-xor-add 纯组合长路径（LUT + 进位链），两端寄存
- `loose.xdc` / `tight.xdc`：10ns / 2ns 两档 `create_clock`
- `run_pass.tcl`：非工程模式单趟实现（read → synth → place → route → timing report → checkpoint）
- `gui.tcl`：GUI 打开 tight 档布线 checkpoint 并调出 Timing Summary 页签（截图用）
- `run.bat` / `launch_gui.bat` / `cap.ps1`：无人值守执行与窗口截图辅助（Windows）

## 复现

```bat
call D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source run_pass.tcl -tclargs loose -log vivado_loose.log
call D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source run_pass.tcl -tclargs tight -log vivado_tight.log
```

产物：`timing_loose.rpt`（WNS 为正）与 `timing_tight.rpt`（WNS 为负、时序违例），对照阅读。
