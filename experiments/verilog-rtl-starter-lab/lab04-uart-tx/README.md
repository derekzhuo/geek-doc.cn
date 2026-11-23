# Lab 04：UART 发送器

**对应教程**：https://geek-doc.cn/chip-design/beginner/seed-verilog-rtl-starter-lab.html

## 这个实验解决什么问题

UART 是芯片世界里最简单也最常见的异步串行接口：调试串口、GPS 模块、蓝牙模组都用它。发送器要把一个字节按固定帧格式并转串发出去，本质上是一个按波特率定时的四状态状态机。

## 模块接口

```verilog
uart_tx #(
  parameter CLKS_PER_BIT = 8   // 一个比特占多少个 clk，波特率 = f_clk / 该值
) (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       start,     // 拉高一个时钟启动一帧
  input  wire [7:0] tx_byte,   // 待发送字节
  output reg        tx,        // 串行数据线
  output reg        done       // 停止位结束后拉高一个时钟
);
```

## 帧格式（8N1）

```text
空闲  起始位   bit0  bit1 ... bit7   停止位  空闲
 1  │   0    │  LSB 最先发送       │   1   │  1
```

- 1 位起始位，固定为 0，告诉接收方数据开始；
- 8 位数据，**低位（LSB）先发**；
- 1 位停止位，固定为 1；
- 没有奇偶校验位，这就是「8N1」名字的由来。

## 设计要点

状态机四个状态：

| 状态 | 行为 |
|---|---|
| IDLE | `tx` 保持空闲高电平，等待 `start` 脉冲并锁存字节 |
| START | 拉低 `tx`，维持 `CLKS_PER_BIT` 个时钟 |
| DATA | 按 `bit_idx` 逐位输出，8 位发完进入 STOP |
| STOP | 拉高 `tx` 一个比特周期，结束时给一个 `done` 脉冲 |

计数器 `c` 在每个状态内数满一个比特周期，`bit_idx` 记录当前发到第几位。真实工程里 `CLKS_PER_BIT` 通常取上百（例如 50 MHz 时钟、9600 波特时约为 5208），仿真里取 8 只是为了快速跑完。

## 怎么跑

```bash
make lab04-uart-tx
```

testbench 连续发送 `0x41`（字符 `A`）和 `0xA5` 两个字节，在每个比特的中点采样 `tx` 并重组字节，检查起始位、停止位、重组结果、`done` 脉冲宽度和两帧之间的空闲电平，共 13 项断言。

## 波形怎么读

```bash
gtkwave lab04-uart-tx/sim_build/lab04.vcd
```

| 信号 | 观察点 |
|---|---|
| `dut.state` | IDLE→START→DATA→STOP 的完整轮转，第二帧再来一遍 |
| `tx` | 下降沿起始，随后 8 个比特 LSB first，最后高电平停止位 |
| `dut.bit_idx` | DATA 状态内 0→7 计数 |
| `done` | 每帧结束时一个时钟宽的脉冲 |

## 自己动手改一改

把 `CLKS_PER_BIT` 从 8 改成 16，先改 testbench 的采样等待节拍再跑仿真，体会比特周期由参数决定；再把 testbench 的字节换成 `0x00` 和 `0xFF`，确认全 0、全 1 这种边界数据的帧格式仍然正确。
