`timescale 1ns/1ps
// CH32V003 USART baud generator behavioral model.
//
// Source basis:
//   - CH32V003 datasheet: factory-calibrated 24 MHz HSI doubled to a
//     48 MHz system/PCLK clock; HSI accuracy after calibration is
//     -1.2%/+1.6% over 0..70 C and +/-2.2% over -40..85 C; HSITRIM[4:0]
//     adjusts about 60 kHz per step at 24 MHz (~0.25% of 48 MHz).
//   - CH32V003 reference manual USART_BRR (STM32F1-compatible):
//     DIV_Mantissa[11:0] + DIV_Fraction[3:0], USARTDIV = mant+frac/16,
//     baud = PCLK / (16 * USARTDIV) with 16x oversampling.
//
// This bench models one bit as an integer number of PCLK cycles
// (16*mant + frac), sweeps eight common rates through the BRR rounding,
// combines the quantization error with each datasheet HSI band, and
// shows the residual after applying the nearest HSITRIM step.
module tb;
  localparam real PCLK_HZ   = 48.0e6;
  localparam real LIM_SOFT  = 2.0;       // practical per-side budget %
  localparam real LIM_HARD  = 5.263;     // 8N1 midpoint sampling limit %
  localparam real TRIM_STEP = 0.25;      // ~60 kHz / 24 MHz, in %

  integer total16;
  integer mant;
  integer frac;
  integer bit_cycles;
  real ideal_div;
  real nominal_baud;
  real quant_pct;
  real hsi_pct;
  real total_err;
  integer k;
  integer trim_steps;
  real trim_residual;

  real rates[0:7];
  real hsi_bands[0:5];

  task run_rate(input real target);
    begin
      ideal_div  = PCLK_HZ / (16.0 * target);
      total16    = $rtoi(ideal_div * 16.0 + 0.5);   // rounded DIV*16
      mant       = total16 / 16;
      frac       = total16 - mant * 16;              // 0..15, carry natural
      bit_cycles = 16 * mant + frac;
      nominal_baud = PCLK_HZ / bit_cycles;
      quant_pct  = (nominal_baud - target) / target * 100.0;
      $display("MEAS RATE target=%0.0f mant=%0d frac=%0d bit_cycles=%0d actual=%.2f quant_pct=%.4f",
               target, mant, frac, bit_cycles, nominal_baud, quant_pct);

      for (k = 0; k < 6; k = k + 1) begin
        hsi_pct   = hsi_bands[k];
        total_err = quant_pct + hsi_pct;
        $display("MEAS HSI target=%0.0f hsi_pct=%.1f total_pct=%.4f soft=%s hard=%s",
                 target, hsi_pct, total_err,
                 ((total_err < -LIM_SOFT) || (total_err > LIM_SOFT)) ? "OUT" : "OK",
                 ((total_err < -LIM_HARD) || (total_err > LIM_HARD)) ? "OUT" : "OK");
      end

      // Nearest HSITRIM correction for the worst industrial band.
      hsi_pct     = -2.2;
      total_err   = quant_pct + hsi_pct;
      trim_steps  = $rtoi((0.0 - total_err) / TRIM_STEP + 0.5);
      trim_residual = total_err + trim_steps * TRIM_STEP;
      $display("MEAS TRIM target=%0.0f worst_pct=%.4f trim_steps=%0d residual_pct=%.4f soft=%s",
               target, total_err, trim_steps, trim_residual,
               ((trim_residual < -LIM_SOFT) || (trim_residual > LIM_SOFT)) ? "OUT" : "OK");
    end
  endtask

  integer r;
  initial begin
    rates[0] = 9600.0;
    rates[1] = 19200.0;
    rates[2] = 38400.0;
    rates[3] = 57600.0;
    rates[4] = 115200.0;
    rates[5] = 230400.0;
    rates[6] = 460800.0;
    rates[7] = 921600.0;
    hsi_bands[0] = -2.2;
    hsi_bands[1] = -1.2;
    hsi_bands[2] = -1.0;
    hsi_bands[3] =  1.0;
    hsi_bands[4] =  1.6;
    hsi_bands[5] =  2.2;
    $display("CHIP=ch32v003 PCLK=48MHz HSI=24MHz-x2 BRR=mant12+frac4");
    for (r = 0; r < 8; r = r + 1) run_rate(rates[r]);
    $display("CH32V003_BENCH_DONE");
    $finish;
  end
endmodule
