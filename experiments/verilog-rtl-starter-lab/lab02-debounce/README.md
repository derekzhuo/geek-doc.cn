# Lab 02：按键消抖

**对应教程**：https://geek-doc.cn/chip-design/beginner/seed-verilog-rtl-starter-lab.html

## 这个实验解决什么问题

机械按键在闭合和松开的瞬间会产生几毫秒的抖动，信号在 0/1 之间快速跳变。如果直接把抖动信号送进数字逻辑，按一次键可能被识别成按了十几次。消抖模块要做两件事：先把异步输入同步进本机时钟域，再要求输入连续稳定 N 个周期才承认电平变化。

## 模块接口

```verilog
debounce #(
  parameter N = 4          // 连续 N 个时钟采样一致才更新电平
) (
  input  wire clk,
  input  wire rst_n,
  input  wire noisy,       // 未经处理的按键输入
  output reg  db_level,    // 消抖后的稳定电平
  output wire db_pulse     // 稳定按下时产生一个时钟宽的脉冲
);
```

## 设计要点

### 两级同步器

`noisy` 与 `clk` 没有相位关系，第一级触发器可能进入亚稳态。两级触发器级联（`noisy → sync1 → sync2`）给亚稳态留出一个完整时钟周期收敛，这是单比特跨时钟域输入最常见的处理方式。

### 稳定计数窗

只有当 `sync2 != db_level` 时计数器才累加；中途输入弹回旧电平，计数器立刻清零。连续数到 `N-1` 才更新 `db_level`，所以任何短于 N 个时钟的抖动都无法穿透。

### 电平与脉冲分开给

- `db_level` 反映按键当前状态，适合直接驱动 LED；
- `db_pulse` 只在「稳定按下」那一拍拉高一个周期，适合做「按一次加一次」的计数使能，松开不产生脉冲。

## 怎么跑

```bash
make lab02-debounce
```

期望输出 6 条 PASS，结尾 `RESULT: PASS`。testbench 先注入三次快速 0/1 抖动，再给一段稳定按下和稳定松开，分别检查电平不变、脉冲数恰好为 1。

## 波形怎么读

```bash
gtkwave lab02-debounce/sim_build/lab02.vcd
```

| 信号 | 观察点 |
|---|---|
| `noisy` | 前段反复跳变的抖动波形，后段保持稳定 |
| `sync1/sync2` | 比 `noisy` 各晚一拍，抖动被逐级削短 |
| `dut.cnt` | 抖动期间在小数值间来回清零，稳定后才一路数到 N-1 |
| `db_pulse` | 全程只出现一个时钟宽的高电平 |

## 自己动手改一改

把参数改成 `N(8)` 后重新仿真，观察 `cnt` 数到 7 才更新电平；再把 testbench 里稳定按下的持续时间从 6 个时钟缩短到 3 个，确认这次按下会被判定为抖动而拒绝，体会稳定窗宽度和响应速度的取舍。
