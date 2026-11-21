# vivado-fifo-generator-ip

**对应教程**：<https://geek-doc.cn/fpga/intermediate/vivado-fifo-generator-ip.html>（随对应教程上线后生效）

用同一组 16×8 同步 FIFO 激励比较 FIFO Generator 与手写 RTL。两者均使用标准读模式与同步复位；IP 配置为块 RAM，手写存储请求 `block` 推断，最终映射以实现报告为准。逐拍检查 full、almost full、empty、almost empty 和输出数据，并覆盖运行中同步复位。器件固定为 Artix-7 `xc7a35ticsg324-1L`，软件为 Vivado/XSim 2017.4。

## 复现（Windows，Vivado 2017.4）

```powershell
powershell -ExecutionPolicy Bypass -File run-fifo.ps1
```

工具路径在脚本顶部，按本机安装位置修改。`setup-ip.tcl` 生成 `fifo_16x8`，仿真显式编译生成的核心顶层、Verilog 行为模型与 wrapper；测试台用独立参考计数器和存储数组逐拍检查两种实现，并覆盖满/空边界、同拍读写、300 拍伪随机流量及运行中同步复位；`fifo_qor.tcl` 分别实现 IP 和手写版本，要求各映射一个块 RAM，且已有 setup/hold 路径不得出现负裕量。脚本会替换本实验的 `work/`、`results/` 和压缩包，不终止其他 Vivado 会话。

时序报告只用于比较本设计的内部寄存器路径。没有板级输入/输出延迟约束，不能据此比较接口时序或板上最高工作频率。

## 本次实测结果

XSim 在满/空边界、同拍读写、300 拍伪随机流量和运行中同步复位场景下完成 378 个非复位检查拍，四种标志与输出数据均和独立参考模型一致：

```text
FIFO_EQUIV_PASS cycles=378 width=8 depth=16
FIFO_RAM_OK variant=ip block_rams=1
FIFO_QOR_RESULT variant=ip wns=6.150 whs=0.067
FIFO_RAM_OK variant=hand block_rams=1
FIFO_QOR_RESULT variant=hand wns=6.665 whs=0.119
```

| 实现 | Slice LUT | Slice Register | RAMB18 | BUFGCTRL | WNS (ns) | WHS (ns) |
|---|---:|---:|---:|---:|---:|---:|
| FIFO Generator | 23 | 30 | 1 | 1 | 6.150 | 0.067 |
| 手写 RTL | 17 | 13 | 1 | 1 | 6.665 | 0.119 |

这些数字只对应上述 16×8 配置、器件和单次实现，不能外推为其他深度、宽度或器件下的固定资源差。原始配置、仿真日志、资源报告和时序报告均保存在 `results/`。
