---
description: 'XDC 约束入门 demo 把时钟、复位按键、拨码开关、LED 输出四类端口凑齐，按 Basys3 官方 master XDC 填真实管脚加 create_clock 逐行注释，演示管脚绑定与时钟定义的完整写法。'
updated: 2026-09-05
---

# xdc-gpio（XDC 约束入门 · 配套 demo）

配套文档：[约束入门 XDC：时钟定义与管脚绑定](/fpga/beginner/05-xdc-constraints-intro.md)。

这个 demo 把「管脚约束要绑的几种端口」凑齐，用来讲清 XDC：时钟、复位按键、拨码开关输入、LED 输出。

| 文件 | 类型 | 说明 |
|------|------|------|
| `gpio_top.v` | 可综合 RTL | `sw[7:0]` 直连 `led[7:0]`（拨哪个开关哪个灯亮，肉眼核对管脚对错）；100MHz 分频出约 1Hz 心跳驱动 `led[15]`；按键 `btn` 高有效复位 |
| `basys3.xdc` | **XDC 约束** | 按 **Digilent Basys3（Artix-7 XC7A35T）** 官方 master XDC 填的真实管脚 + `create_clock`，每行注释；**其它板子必须照自己 master XDC/原理图改管脚号** |
| `gpio_top_tb.v` | testbench | 小参数快速验证 sw→led 直通、按键复位、心跳翻转（iverilog/Vivado Sim 可跑） |

## 上板（Vivado）

1. 新建工程，器件选 `xc7a35tcpg236-1`（Basys3）。
2. 加入 `gpio_top.v` 与 `basys3.xdc`（Add Sources → Constraints）。
3. Run Synthesis → Run Implementation → Generate Bitstream → Program Device。
4. 现象：低 8 颗 LED 跟随 8 位拨码开关；最右 `led[15]` 约每秒翻转一次；按中央按键 btnC 心跳复位。

> 不是 Basys3？把 `basys3.xdc` 里每个 `PACKAGE_PIN` 换成你板子 master XDC 里对应 `clk/btn/sw/led` 的脚号，并确认 `IOSTANDARD`（3.3V 单端一般是 LVCMOS33）；时钟脚还要把 `create_clock -period` 改成你晶振的周期（100MHz=10ns，50MHz=20ns）。

## 仿真（iverilog，可选）

```bash
iverilog -o gpio_sim gpio_top.v gpio_top_tb.v
vvp gpio_sim        # 应打印 GPIO TOP SELF-CHECK *** PASSED ***
gtkwave gpio_top_tb.vcd
```

## 一句话总结

**一句话总结**：这个 demo 用开关直通 LED + 心跳灯，把 XDC 的两类约束讲全——`PACKAGE_PIN`/`IOSTANDARD` 定物理管脚与电平、`create_clock` 定时钟周期作时序分析基准；管脚号照板子 master XDC 填、时钟周期照晶振填，就能综合实现上板看到现象。
