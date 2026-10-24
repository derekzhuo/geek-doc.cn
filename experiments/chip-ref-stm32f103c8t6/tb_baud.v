`timescale 1ns/1ps
// STM32F103 USART 波特率发生器硬件行为复现：
// 硬件语义 = 每 clk 累加 16，累加到 BRR 进位产生一次 16 倍过采样 tick（即 bit tick = 过采样/16，
// 等效 bit 周期 = BRR/APB 秒）。BRR = round(APB/baud)。
module tb;
  localparam real BAUD = 115200.0;

  reg clk36 = 0; reg clk72 = 0;
  always #(13.889) clk36 = ~clk36;   // 36MHz
  always #(6.944) clk72 = ~clk72;    // 72MHz

  localparam integer BRR36 = 313;  // 36e6/115200 = 312.5 -> 313
  localparam integer BRR72 = 625;  // 72e6/115200 = 625.0 精确

  reg [15:0] acc36 = 0; reg otick36 = 0;
  reg [15:0] acc72 = 0; reg otick72 = 0;
  always @(posedge clk36) begin
    if (acc36 + 16 >= BRR36) begin acc36 <= acc36 + 16 - BRR36; otick36 <= 1; end
    else begin acc36 <= acc36 + 16; otick36 <= 0; end
  end
  always @(posedge clk72) begin
    if (acc72 + 16 >= BRR72) begin acc72 <= acc72 + 16 - BRR72; otick72 <= 1; end
    else begin acc72 <= acc72 + 16; otick72 <= 0; end
  end

  integer n36 = 0; integer t036 = 0; integer t136 = 0;
  integer n72 = 0; integer t072 = 0; integer t172 = 0;
  real o36, o72, b36, b72, e36, e72;
  always @(posedge clk36) if (otick36) begin
    n36 = n36 + 1; if (n36 == 1) t036 = $time; if (n36 == 1025) t136 = $time;
  end
  always @(posedge clk72) if (otick72) begin
    n72 = n72 + 1; if (n72 == 1) t072 = $time; if (n72 == 1025) t172 = $time;
  end
  always @(posedge clk72) if (t136 != 0 && t172 != 0) begin
    o36 = (t136 - t036) / 1024.0;  // 过采样 tick 平均周期
    o72 = (t172 - t072) / 1024.0;
    b36 = 1.0e9 / (o36 * 16.0); e36 = (b36 - BAUD) / BAUD * 100.0;
    b72 = 1.0e9 / (o72 * 16.0); e72 = (b72 - BAUD) / BAUD * 100.0;
    $display("CHIP=stm32f103c8t6 TARGET_BAUD=%0d  (BRR=round(APB/baud), 16x oversampling)", BAUD);
    $display("MEAS APB1=36MHz BRR=%0d avg_bit_ns=%.2f actual_baud=%.1f error_pct=%.3f", BRR36, o36*16.0, b36, e36);
    $display("MEAS APB2=72MHz BRR=%0d avg_bit_ns=%.2f actual_baud=%.1f error_pct=%.3f", BRR72, o72*16.0, b72, e72);
    $finish;
  end
endmodule
