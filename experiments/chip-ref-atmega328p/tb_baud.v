`timescale 1ns/1ps
// ATmega328P USART 波特率发生器硬件行为复现：16MHz 主频，UBRR 整数分频
// U2X=0: baud = fosc/(16*(UBRR+1)); U2X=1: baud = fosc/(8*(UBRR+1))
module tb;
  localparam real CLK_HZ = 16000000.0;
  localparam real BAUD   = 115200.0;
  localparam integer UBRR_N = 8;   // 正常模式取整：16000000/16/115200-1 = 7.68 -> 8
  localparam integer UBRR_D = 16;  // U2X=1 模式：16000000/8/115200-1 = 16.36 -> 16

  reg clk = 0;
  always #(31.25) clk = ~clk;   // 16MHz: 半周期 31.25ns

  reg [15:0] cnt_n = 0; reg tick_n = 0;
  reg [15:0] cnt_d = 0; reg tick_d = 0;
  always @(posedge clk) begin
    if (cnt_n == 16*(UBRR_N+1)-1) begin cnt_n <= 0; tick_n <= 1; end
    else begin cnt_n <= cnt_n + 1; tick_n <= 0; end
    if (cnt_d == 8*(UBRR_D+1)-1) begin cnt_d <= 0; tick_d <= 1; end
    else begin cnt_d <= cnt_d + 1; tick_d <= 0; end
  end

  integer bits_n = 0; integer t0_n = 0; integer t1_n = 0;
  integer bits_d = 0; integer t0_d = 0; integer t1_d = 0;
  real an, ad, bn, bd, en, ed;
  always @(posedge clk) begin
    if (tick_n) begin
      bits_n = bits_n + 1;
      if (bits_n == 1) t0_n = $time;
      if (bits_n == 65) t1_n = $time;
    end
    if (tick_d) begin
      bits_d = bits_d + 1;
      if (bits_d == 1) t0_d = $time;
      if (bits_d == 65) t1_d = $time;
    end
    if (t1_n != 0 && t1_d != 0) begin
      an = (t1_n - t0_n) / 64.0; bn = 1.0e9 / an; en = (bn - BAUD) / BAUD * 100.0;
      ad = (t1_d - t0_d) / 64.0; bd = 1.0e9 / ad; ed = (bd - BAUD) / BAUD * 100.0;
      $display("CHIP=atmega328p FOSC=%0dM TARGET_BAUD=%0d", CLK_HZ/1.0e6, BAUD);
      $display("MEAS U2X=0 UBRR=%0d avg_bit_ns=%.2f actual_baud=%.1f error_pct=%.3f", UBRR_N, an, bn, en);
      $display("MEAS U2X=1 UBRR=%0d avg_bit_ns=%.2f actual_baud=%.1f error_pct=%.3f", UBRR_D, ad, bd, ed);
      $display("VERDICT: %s", (en > 2.0 || en < -2.0) ? "U2X=0 outside +-2pct window, U2X=1 required" : "both within +-2pct window");
      $finish;
    end
  end
endmodule
