`timescale 1ns/1ps
// STM32F407 PLL 时钟链硬件行为复现 + 合法性校验（RM0090 时钟树约束）：
// HSE 8MHz -> /PLLM -> 1MHz -> ×PLLN -> VCO -> /PLLP -> SYSCLK, /PLLQ -> USB48
// 约束：PLL 输入 1~2MHz；VCO 192~432MHz；SYSCLK ≤168MHz；USB = 48MHz ±0.25%
module tb;
  localparam real HSE_NS = 125.0;  // 8MHz

  task run_cfg(input integer M, input integer N, input integer P, input integer Q);
    real vco_mhz, sys_mhz, usb_mhz, fin_mhz; integer ok;
    begin
      fin_mhz = 8.0 / M;
      vco_mhz = fin_mhz * N;
      sys_mhz = vco_mhz / P;
      usb_mhz = vco_mhz / Q;
      ok = 1;
      if (fin_mhz < 0.95 || fin_mhz > 2.1) ok = 0;
      if (vco_mhz < 192.0 || vco_mhz > 432.0) ok = 0;
      if (sys_mhz > 168.0) ok = 0;
      if (usb_mhz < 47.88 || usb_mhz > 48.12) ok = 0;
      $display("CFG M=%0d N=%0d P=%0d Q=%0d -> Fin=%.3fMHz VCO=%.1fMHz SYSCLK=%.1fMHz USB=%.3fMHz %s",
               M, N, P, Q, fin_mhz, vco_mhz, sys_mhz, usb_mhz, ok ? "LEGAL" : "ILLEGAL");
    end
  endtask

  // 对一组合法配置做「真实分频」：由 HSE 相位累加器生成 VCO 节拍，再计数分频出 SYSCLK，
  // 频计实测量到的 SYSCLK 频率，与理论 168MHz 对照（验证模型不是纸面算术）
  reg hse = 0;
  always #(HSE_NS/2) hse = ~hse;

  localparam integer M = 8; localparam integer N = 336; localparam integer P = 2;
  reg [15:0] acc = 0; reg vco_tick = 0;
  // VCO = HSE/M*N = 8/8*336 = 336MHz：每 HSE 周期 N/M=42 个 VCO 拍
  always @(posedge hse) begin : vco_gen
    integer i;
    for (i = 0; i < N/M; i = i + 1) begin
      #(HSE_NS*M/N/2) vco_tick = 1; #(1) vco_tick = 0;
    end
  end

  reg sys = 0; integer vc = 0;
  always @(posedge vco_tick) begin
    vc = vc + 1;
    if (vc % (P/2) == 0) sys = ~sys;   // 每 P/2 拍翻转一次 => 周期 = P 个 VCO 拍 => /P 分频
  end

  integer edges = 0; integer t0 = 0;
  real meas_mhz;
  always @(posedge sys) begin
    edges = edges + 1;
    if (edges == 10) t0 = $time;
    if (edges == 178) begin
      meas_mhz = 168.0 / (($time - t0) / 1000.0);  // 168 个周期耗时 ns /1000 = us，cycles/us = MHz
      $display("MEAS freq-counter: 168 SYSCLK cycles took %0d ns -> SYSCLK = %.2f MHz (theory 168.00)",
               $time - t0, meas_mhz);
      $finish;
    end
  end

  initial begin
    $display("PLL legality sweep (HSE=8MHz, RM0090 constraints):");
    run_cfg(8, 336, 2, 7);    // 官方标准配置 168MHz + 48MHz USB
    run_cfg(8, 360, 2, 7);    // VCO 360MHz 合法但 360/7=51.4MHz USB 越界
    run_cfg(4, 168, 2, 7);    // Fin=2MHz 边界合法
    run_cfg(8, 500, 2, 10);   // VCO 500MHz 越界
    run_cfg(8, 336, 4, 7);    // SYSCLK=84MHz 合法（降频档）
    #2000000;
    $display("TIMEOUT: sys edges not enough");
    $finish;
  end
endmodule
