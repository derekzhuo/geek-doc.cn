`timescale 1ns/1ps
// ESP32-WROOM-32 UART 波特率发生器硬件行为复现：
// APB=80MHz，CLKDIV = 整数部分 + 4bit 小数（1/16 分辨率），bit 周期 = CLKDIV/APB。
// 目标档位：115200 / 921600（ESP32 常用高速档）
module tb;
  reg clk = 0;
  always #(6.25) clk = ~clk;   // 80MHz

  // 115200: 80e6/115200 = 694.444 -> int 694, frac = round(0.4444*16) = 7 -> 694.4375
  localparam integer DV0 = 694*16 + 7;
  // 921600: 80e6/921600 = 86.806 -> int 86, frac = round(0.8056*16) = 13 -> 86.8125
  localparam integer DV1 = 86*16 + 13;

  reg [15:0] acc0 = 0; reg tick0 = 0;
  reg [15:0] acc1 = 0; reg tick1 = 0;
  always @(posedge clk) begin
    if (acc0 + 16 >= DV0) begin acc0 <= acc0 + 16 - DV0; tick0 <= 1; end
    else begin acc0 <= acc0 + 16; tick0 <= 0; end
    if (acc1 + 16 >= DV1) begin acc1 <= acc1 + 16 - DV1; tick1 <= 1; end
    else begin acc1 <= acc1 + 16; tick1 <= 0; end
  end

  integer n0 = 0; integer t00 = 0; integer t10 = 0;
  integer n1 = 0; integer t01 = 0; integer t11 = 0;
  real a0, a1, b0, b1, e0, e1;
  always @(posedge clk) begin
    if (tick0) begin n0 = n0 + 1; if (n0 == 1) t00 = $time; if (n0 == 65) t10 = $time; end
    if (tick1) begin n1 = n1 + 1; if (n1 == 1) t01 = $time; if (n1 == 65) t11 = $time; end
    if (t10 != 0 && t11 != 0) begin
      a0 = (t10 - t00) / 64.0; b0 = 1.0e9 / a0; e0 = (b0 - 115200.0) / 115200.0 * 100.0;
      a1 = (t11 - t01) / 64.0; b1 = 1.0e9 / a1; e1 = (b1 - 921600.0) / 921600.0 * 100.0;
      $display("CHIP=esp32-wroom-32 APB=80MHz CLKDIV=int+frac(4bit)");
      $display("MEAS target=115200 div=%0d.%0d avg_bit_ns=%.2f actual_baud=%.1f error_pct=%.3f", DV0/16, DV0%16, a0, b0, e0);
      $display("MEAS target=921600 div=%0d.%0d avg_bit_ns=%.2f actual_baud=%.1f error_pct=%.3f", DV1/16, DV1%16, a1, b1, e1);
      $finish;
    end
  end
endmodule
