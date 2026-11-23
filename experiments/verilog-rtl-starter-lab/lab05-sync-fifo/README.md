# Lab 05：参数化同步 FIFO

**对应教程**：https://geek-doc.cn/chip-design/beginner/seed-verilog-rtl-starter-lab.html

## 这个实验解决什么问题

两个处理速度不同的模块对接时，需要一块缓冲把突发数据暂存下来，让写侧和读侧各按自己的节奏工作。先进先出存储器（FIFO）就是数据通路里最常用的缓冲结构。本实验实现单时钟同步 FIFO——读写双方共用一个时钟，不涉及跨时钟域的复杂问题。

## 模块接口

```verilog
sync_fifo #(
  parameter WIDTH = 8,    // 每个数据的位宽
  parameter DEPTH = 16    // 容量，必须是 2 的幂
) (
  input  wire             clk, rst_n,
  input  wire             wr_en, rd_en,
  input  wire [WIDTH-1:0] wr_data,
  output wire [WIDTH-1:0] rd_data,
  output wire             full, empty,
  output reg  [$clog2(DEPTH):0] count
);
```

## 设计要点

### 指针 + 存储器

`mem` 是寄存器阵列，`wr_ptr`/`rd_ptr` 分别指向下一个写入位置和当前读取位置。深度取 2 的幂时，指针靠自然溢出回卷，不需要比较判断。

### 用占用计数判满空

`count` 实时记录 FIFO 里有多少个数据：

- 只写不读，`count + 1`；
- 只读不写，`count - 1`；
- 同时读写，一进一出，`count` 不变。

`full = (count == DEPTH)`、`empty = (count == 0)`，满空条件一目了然。内部进一步用 `do_wr = wr_en && !full`、`do_rd = rd_en && !empty` 把门控做死：满时写入、空时读取都会被直接忽略，不会破坏指针。

### 同步与异步的边界

本实验只有一个时钟，所以叫**同步 FIFO**。真正的跨时钟域 FIFO（异步 FIFO）需要 Gray Code 指针和两级同步器，是后续进阶专题的内容，不在本工程包范围内。

## 怎么跑

```bash
make lab05-sync-fifo
```

testbench 在 16 深例化上验证：复位空态、连续写满、满写忽略、按写入顺序逐个读出、读空、空读忽略；再用一个独立的 4 深例化验证改参数后满空阈值和数据顺序仍然正确，共 29 项断言。

## 波形怎么读

```bash
gtkwave lab05-sync-fifo/sim_build/lab05.vcd
```

| 信号 | 观察点 |
|---|---|
| `dut.count` | 写入阶段一路涨到 16，读取阶段逐拍回 0 |
| `full/empty` | 分别在 count 触顶和归零时翻转 |
| `dut.wr_ptr/dut.rd_ptr` | 写时写指针前进，读时读指针追赶，回卷处注意观察 |
| `rd_data` | 组合输出，`rd_ptr` 指向谁就输出谁，读使能当拍即可采样 |

## 自己动手改一改

把例化参数改成 `DEPTH(8)`、`WIDTH(16)`，同步修改 testbench 的写入次数和数据位宽后重跑；再尝试在同一拍同时拉高 `wr_en` 和 `rd_en`，在波形里确认 `count` 保持不动、数据顺序不乱，这就是 FIFO 同时读写的稳态工作方式。
