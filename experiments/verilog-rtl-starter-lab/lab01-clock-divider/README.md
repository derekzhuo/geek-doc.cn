# Lab 01：参数化时钟分频器

**对应教程**：https://geek-doc.cn/chip-design/beginner/seed-verilog-rtl-starter-lab.html

## 这个实验解决什么问题

数字电路里经常需要比系统时钟更慢的节拍：LED 闪烁、串口采样定时、低速外设使能。最基础的做法是用一个计数器数满 N 个时钟周期后翻转输出，这就是时钟分频。

## 模块接口

```verilog
clock_divider #(
  parameter DIV = 4          // 输出每 DIV 个 clk 翻转一次
) (
  input  wire clk,
  input  wire rst_n,         // 低电平有效，异步复位
  output reg  out
);
```

频率关系：

```text
f_out = f_clk / (2 × DIV)
```

`DIV=4`、`f_clk=100 MHz` 时，`out` 频率为 12.5 MHz。注意翻转一次需要 `DIV` 个时钟，而一个完整周期包含两次翻转，所以分母有个 2。

## 设计要点

- 计数器位宽用 `$clog2(DIV)` 自动计算，改参数不用手动改位宽。
- 数到 `DIV-1` 时计数器归零并翻转 `out`，其余时刻只累加。
- 复位同时清计数器和输出，保证仿真和上板起点一致。

## 怎么跑

在工程包根目录执行：

```bash
make lab01-clock-divider
```

期望输出：

```text
  PASS: out toggles once every DIV input clocks
  ...
RESULT: PASS
```

## 波形怎么读

仿真会生成 `lab01-clock-divider/sim_build/lab01.vcd`，用 GTKWave 打开：

```bash
gtkwave lab01-clock-divider/sim_build/lab01.vcd
```

重点看三个信号：

| 信号 | 观察点 |
|---|---|
| `clk` | 10 ns 周期的输入时钟 |
| `dut.cnt` | 0→1→2→3 循环，数到 3 后归零 |
| `out` | 每 4 个 `clk` 翻转一次，周期是 `clk` 的 8 倍 |

testbench 用时钟周期计数而不是时间数值来判断翻转间隔，这样改 `timescale` 也不会让测试失效。

## 自己动手改一改

把例化参数从 `DIV(4)` 改成 `DIV(8)`，重新跑仿真，在波形里确认 `out` 变成每 8 个时钟翻转一次；再想想为什么 testbench 里的检查项需要同步修改。
