# vivado-rtl-to-bitstream-webpack

**对应教程**：https://geek-doc.cn/fpga/beginner/exp-vivado-rtl-to-bitstream-webpack.html

Vivado WebPACK（2017.4 免费授权档）从 RTL 到比特流的完整流程复现：工程模式批处理跑综合 → 实现 → 生成 `.bit`，附利用率与时序报告。

## 内容

- `top.v`：27 位计数器，高 4 位驱动 LED（Arty A7-35T，xc7a35tcsg324-1）
- `top.xdc`：板卡引脚与 100MHz 时钟约束
- `build.tcl`：工程模式批处理全流程（create_project → synth_1 → impl_1 → write_bitstream → 报告）
- `gui.tcl`：GUI 打开完成后的工程（截图用）
- `run.bat` / `launch_gui.bat` / `cap.ps1`：无人值守执行与窗口截图辅助（Windows）

## 复现

装好 Vivado 2017.4（WebPACK 授权即可，xc7a35t 在免费范围）后：

```bat
call D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source build.tcl -log vivado_build.log
```

产物：`blink_proj/blink.runs/impl_1/blink_top.bit`、`util.rpt`、`timing.rpt`。
