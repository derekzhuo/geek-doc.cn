# vivado-clock-wizard-mmc

**对应教程**：<https://geek-doc.cn/fpga/intermediate/vivado-clock-wizard-mmc.html>（随对应教程上线后生效）

用 Clocking Wizard 把 100MHz 输入配置为 50MHz 与 200MHz 两路输出，验证 `locked`、仿真周期、派生时钟约束和布线后时序。器件固定为 Artix-7 `xc7a35ticsg324-1L`，软件为 Vivado/XSim 2017.4。

## 复现（Windows，Vivado 2017.4）

```powershell
powershell -ExecutionPolicy Bypass -File run-clock.ps1
```

工具路径在脚本顶部，按本机安装位置修改。`setup-ip.tcl` 创建 `clk_wiz_0` 并生成行为模型，测试台测量两路输出各 20 个周期；`clock_qor.tcl` 综合 IP、实现顶层并导出 `report_clocks`、资源和时序报告。脚本会替换本实验的 `work/`、`results/` 和压缩包，不终止其他 Vivado 会话。

## 实测结果（Vivado/XSim 2017.4）

| 检查项 | 实测结果 |
|---|---|
| `locked` | 545.100ns 时检测到 1；测试台要求锁定不超过 1500ns |
| 50MHz 输出 | 仿真 20 周期平均 20.000000ns；`report_clocks` 派生周期 20.000ns |
| 200MHz 输出 | 仿真 20 周期平均 5.000000ns；`report_clocks` 派生周期 5.000ns |
| 布线后时序 | WNS 2.806ns，WHS 0.240ns，均非负 |
| 逻辑资源 | 12 Slice LUT、16 Slice Register |
| 时钟资源 | 1 个 MMCME2_ADV、3 个 BUFGCTRL |

`results/` 保留 IP 配置、编译/仿真日志和布线后时钟、资源、时序报告。派生时钟分别落在 MMCM 的 `CLKOUT0` 与 `CLKOUT1`；三个全局缓冲分别对应输入时钟和两路输出时钟。

XSim 2017.4 的 Verilog 仿真需要同时编译 wrapper `clk_wiz_0.v` 和核心模型 `clk_wiz_0_clk_wiz.v`，并用 `unisims_ver` 与 `unimacro_ver` 链接 primitive 模型。这里的 WNS/WHS 来自布线后实现报告，不是 IP 参数页面里的请求值。
