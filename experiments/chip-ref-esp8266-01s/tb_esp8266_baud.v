`timescale 1ns/1ps
// ESP8266 (ESP-01S) UART baud generator behavioral model.
//
// Source basis: ESP8266 RTOS SDK driver/uart.c writes
//   UART[num]->clk_div.val = (UART_CLK_FREQ / baud_rate) & 0xFFFFF;
// where UART_CLK_FREQ = 80 MHz and clk_div is a 20-bit integer-only
// divider (uart_struct.h: div_int:20). There is no fractional field in
// the current SDK register view, so baud quantization is integer-only.
//
// This bench:
//   1. runs a cycle-accurate 80 MHz tick generator with the integer
//      divider and measures the real bit period over 64 ticks;
//   2. sweeps nine common baud rates and reports quantization error;
//   3. adds external crystal tolerance scenarios (the APB clock is
//      derived from the 40 MHz crystal, typically +/-10..50 ppm);
//   4. computes the same rates with a 4-bit fractional divider
//      (ESP32-style) for contrast, to quantify the integer-only cost.
module tb;
  localparam real APB_HZ     = 80.0e6;
  localparam real CLK_NS     = 6.25;       // half period of 80 MHz clock
  localparam real LIM_SOFT   = 2.0;        // practical per-side budget %
  localparam real LIM_HARD   = 5.263;      // 8N1 midpoint sampling limit %

  reg clk = 0;
  always #CLK_NS clk = ~clk;

  reg [31:0] div = 1;
  reg [31:0] acc = 0;
  reg        tick = 0;
  integer    ntick = 0;
  integer    t0 = 0;
  integer    t1 = 0;

  always @(posedge clk) begin
    if (acc + 32'd1 >= div) begin
      acc  <= acc + 32'd1 - div;
      tick <= 1;
    end else begin
      acc  <= acc + 32'd1;
      tick <= 0;
    end
  end

  always @(posedge clk) begin
    if (tick) begin
      ntick <= ntick + 1;
      if (ntick == 0)  t0 <= $time;
      if (ntick == 64) t1 <= $time;
    end
  end

  integer r;
  real target;
  real bit_ns;
  real actual;
  real qerr;
  real xtal_ppm;
  real total_err;
  real fdiv;
  real fbaud;
  real ferr;
  integer frac_raw;

  // Common ESP8266 UART rates, including the 74880 boot log rate.
  real rates[0:8];

  task reset_counters;
    begin
      acc   = 0;
      tick  = 0;
      ntick = 0;
      t0    = 0;
      t1    = 0;
      @(posedge clk);
    end
  endtask

  task run_rate(input real baud_target);
    integer k;
    begin
      target = baud_target;
      div    = $rtoi(APB_HZ / target);   // SDK integer truncation
      reset_counters;
      wait (t1 != 0);
      @(posedge clk);
      bit_ns = (t1 - t0) / 64.0;
      actual = 1.0e9 / bit_ns;
      qerr   = (actual - target) / target * 100.0;
      $display("MEAS RATE target=%0.0f div=%0d bit_ns=%.3f actual=%.2f quant_pct=%.4f",
               target, div, bit_ns, actual, qerr);

      // Crystal-derived APB error adds linearly to the baud error.
      for (k = 0; k < 4; k = k + 1) begin
        if (k == 0) xtal_ppm = -10.0;
        if (k == 1) xtal_ppm =  10.0;
        if (k == 2) xtal_ppm = -50.0;
        if (k == 3) xtal_ppm =  50.0;
        total_err = qerr + xtal_ppm / 10000.0;
        $display("MEAS XTAL target=%0.0f xtal_ppm=%0.0f total_pct=%.4f soft=%s hard=%s",
                 target, xtal_ppm, total_err,
                 ((total_err < -LIM_SOFT) || (total_err > LIM_SOFT)) ? "OUT" : "OK",
                 ((total_err < -LIM_HARD) || (total_err > LIM_HARD)) ? "OUT" : "OK");
      end

      // ESP32-style 4-bit fractional divider on the same 80 MHz clock.
      frac_raw = $rtoi((APB_HZ / target - div) * 16.0 + 0.5);
      if (frac_raw > 15) frac_raw = 15;
      fdiv     = div + frac_raw / 16.0;
      fbaud    = APB_HZ / fdiv;
      ferr     = (fbaud - target) / target * 100.0;
      $display("MEAS FRAC target=%0.0f fdiv=%.4f frac_actual=%.2f frac_pct=%.4f",
               target, fdiv, fbaud, ferr);
    end
  endtask

  initial begin
    rates[0] = 9600.0;
    rates[1] = 19200.0;
    rates[2] = 38400.0;
    rates[3] = 57600.0;
    rates[4] = 74880.0;
    rates[5] = 115200.0;
    rates[6] = 230400.0;
    rates[7] = 460800.0;
    rates[8] = 921600.0;
    $display("CHIP=esp8266-esp-01s APB=80MHz divider=integer20 (RTOS SDK)");
    for (r = 0; r < 9; r = r + 1) run_rate(rates[r]);
    $display("ESP8266_BENCH_DONE");
    $finish;
  end
endmodule
