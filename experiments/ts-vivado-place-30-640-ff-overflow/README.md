# ts-vivado-place-30-640-ff-overflow

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-place-30-640-ff-overflow.html>（上线后生效）

Vivado 放置阶段触发器资源不足的对照实验：同一条移位寄存器链，坏版本在
xc7a35t 上例化 60000 个显式触发器（`SHREG_EXTRACT = "no"` 加
`DONT_TOUCH` 防止被综合成 SRL LUT），超出器件 41600 个触发器站点的上限，
`place_design` 报 `[Place 30-640]` 后中止；修复版本只把链长降到 2000，
结构与约束完全不变，放置通过，`report_utilization` 显示 Slice Registers
占用 2000/41600（4.81%）。

## 文件

- `v10_overflow_bad.v` —— 坏版本：60000 级显式 FF 移位链，超出 xc7a35t 触发器上限
- `v10_overflow_fixed.v` —— 修复版本：同构 2000 级链，器件容量内
- `v10_err.tcl` —— 坏版本批处理脚本：综合后 `catch` 包裹 `place_design`，打印 `V10_BAD_PLACE_ERROR`
- `v10_fix.tcl` —— 修复版本脚本：放置成功后 `report_utilization`，打印 `V10_FIX_PLACE_OK`
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-place-overflow.log` —— 真实报错日志：两条 `[Place 30-640]`（Flip Flop 与 Slice Registers 各一条），60000 需求对 41600 站点
- `fix-place-utilization.log` —— 修复后真实日志：放置通过，Slice Registers 2000/41600（4.81%）

## 复现（Windows，Vivado 2017.4）

```bat
rem 坏版本：综合通过，place_design 报 [Place 30-640]
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v10_err.tcl

rem 修复版本：放置通过，报告 4.81% 触发器占用
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v10_fix.tcl
```

坏版本日志里的关键签名：`ERROR: [Place 30-640] Place Check : This design
requires more Register as Flip Flop cells than are available in the target
device. This design requires 60000 of such cell types but only 41600
compatible sites are available`，随后 `[Place 30-99] Placer failed` 收尾。
注意综合阶段本身是 0 errors——资源超限是在放置可行性检查才暴露的，只看
综合退出码会误判设计可用。
