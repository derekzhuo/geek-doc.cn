# vivado-xpm-cdc-synchronizer

**对应教程**：<https://geek-doc.cn/fpga/intermediate/vivado-xpm-cdc-synchronizer.html>（随对应教程上线后生效）

比较 XPM `xpm_cdc_single` 与手写两级触发器单比特同步器。两者都使用两级目的时钟寄存器、无源时钟输入寄存器；手写版本显式标记 `ASYNC_REG=TRUE`。

## 复现（Windows，Vivado/XSim 2017.4）

```powershell
powershell -ExecutionPolicy Bypass -File run-cdc.ps1
```

脚本显式编译 Vivado 安装目录中的 `xpm_cdc.sv` 与 `glbl.v`，以 `work.tb_cdc work.glbl` 为仿真顶层，不依赖预编译 XPM 库。随后运行异步时钟等价测试，再分别综合、优化、布局和布线。固定器件为 Artix-7 `xc7a35ticsg324-1L`，源时钟 7ns、目的时钟 10ns，并声明异步时钟组；工具路径在脚本顶部，按本机安装位置修改。

源输入在 7ns 时钟域内伪随机变化，目的域每拍比较两个输出，共检查 512 拍。全部一致才输出 `CDC_EQUIV_PASS cycles=512`。综合阶段按 `ASYNC_REG == TRUE` 筛选并打印两种实现的同步寄存器属性，资源及时序报告收进 `cdc-results.zip`。

## 本次实测（2026-11-22）

| 实现 | ASYNC_REG 单元 | Slice LUT | Slice Register | WNS | WHS |
|---|---:|---:|---:|---:|---:|
| XPM `xpm_cdc_single` | 2 | 0 | 2 | 9.262ns | 0.131ns |
| 手写两级触发器 | 2 | 0 | 2 | 9.262ns | 0.131ns |

XPM 的属性落在 `sync_inst/syncstages_ff_reg[0]` 与 `[1]`，手写版本落在 `sync1_reg` 与 `sync2_reg`，Vivado 日志把布尔属性打印为 `1`。两实现均通过 512 拍逐拍输出一致性检查，setup/hold failing endpoints 均为 0。相同资源和裕量只说明这份最小单比特设计在当前器件与约束下映射一致，不代表其他位宽、复位或目的域逻辑下也完全相同。

等价结果只覆盖两寄存器、无源输入寄存器这一配置。它不能证明跨时钟传输必然亚稳态安全，也不适用于多比特总线的数据一致性；实际工程仍需按复位、初始化和时序例外要求审查完整路径。完整编译、仿真、实现日志与资源/时序报告位于 `results/`。
