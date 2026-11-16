# ts-vivado-xdc-constraint-order

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-xdc-constraint-order.html>（上线后生效）

同一端口被两个 XDC 文件先后赋予不同 `IOSTANDARD` 时，Vivado 不会让两个值并存，最终属性由 `read_xdc` 的加载顺序决定：后读的约束覆盖先读的约束。

- **33 → 18**：先读 `level_33.xdc`，再读 `level_18.xdc`，综合后 `report_property [get_ports en]` 显示 `IOSTANDARD ... LVCMOS18`。
- **18 → 33**：交换两个 `read_xdc` 的顺序后，同一报告显示 `IOSTANDARD ... LVCMOS33`。
- 两组流程均无真实 `CRITICAL WARNING`，说明问题不一定以报错形式出现，最终要以端口属性报告核对。

## 文件

- `constraint_order.v` —— 带使能端的四位计数器
- `level_33.xdc` / `level_18.xdc` —— 分别把 `en` 设为 LVCMOS33、LVCMOS18
- `order_33_then_18.tcl` / `order_18_then_33.tcl` —— 两种 XDC 加载顺序
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `order-33-then-18.log` / `order-18-then-33.log` —— Vivado 2017.4 真实输出

## 复现（Windows，Vivado 2017.4）

```bat
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source order_33_then_18.tcl
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source order_18_then_33.tcl
```

排查时不要只搜错误码。约束覆盖可能安静发生，应在综合后执行 `report_property [get_ports en]`，用报告中的最终属性反推 XDC 加载顺序；多文件约束工程还要固定 `read_xdc` 顺序，避免文件列表调整后板级电平标准悄悄改变。
