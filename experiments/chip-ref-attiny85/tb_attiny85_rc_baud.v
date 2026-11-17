`timescale 1ns/1ps
// ATtiny85 internal 8 MHz RC oscillator -> bit-bang UART baud error budget.
//
// The ATtiny85 has no hardware USART: a software UART burns an integer number
// of CPU cycles per bit, and the only time base on a crystal-less board is the
// calibrated internal RC oscillator. This behavior-level model separates the
// two error sources and exercises the OSCCAL trim:
//   - divider error: ideal 69.444 cycles/bit at 115200 must round to 69 or 70
//   - oscillator error: uncalibrated +/-10% bound, factory-calibrated +/-1%
//     bound (datasheet-class accuracy figures, treated as model parameters)
//   - OSCCAL: 8-bit trim code, model step 0.5% of nominal per LSB around the
//     factory code 128 (step coefficient is a model parameter, re-check the
//     ATtiny85 datasheet trim curve before quoting absolute code counts)
// Bit periods are measured over 32 real bit ticks, the same method as the
// ATmega328P baud-generator bench, so the two experiments cross-check.
// Six scenarios, each one MEAS line:
//   S1 bitbang_quant      integer cycle divider at 115200, zero drift
//   S2 uncal_worst        +/-10% drift vs the +/-5.263% midpoint sample limit
//   S3 factory_cal        +/-1% drift inside the +/-2% working window
//   S4 osccal_sweep       256 trim codes, counts inside each window
//   S5 trim_back          worst-case +/-10% units trimmed back by OSCCAL
//   S6 baud9600           low baud shrinks divider error, RC drift unchanged
module tb;
  localparam real F_NOM   = 8.0e6;
  localparam real BAUD115 = 115200.0;
  localparam real BAUD96  = 9600.0;
  // Midpoint-sampling theoretical limit: +/-0.5 bit over a 9.5-bit frame.
  localparam real LIM_PCT = 100.0 * (0.5 / 9.5);
  localparam integer CAL_CODE = 128;
  localparam real STEP_PCT   = 0.005; // 0.5% of nominal per OSCCAL LSB

  reg clk = 0;
  real half_ns = 62.5; // 8 MHz default half period
  always #half_ns clk = ~clk;

  // Software-UART bit tick: one pulse every div_n CPU clock cycles.
  reg [15:0] divcnt;
  integer div_n;
  reg bit_tick;
  initial begin divcnt = 0; div_n = 69; bit_tick = 0; end
  always @(posedge clk) begin
    if (divcnt >= div_n - 1) begin
      divcnt <= 0;
      bit_tick <= 1;
    end else begin
      divcnt <= divcnt + 1;
      bit_tick <= 0;
    end
  end

  real f_osc;
  real t0, t1, m_ns, m_baud, m_err;
  real ep, em;
  integer code;
  integer win2, winlim;
  integer best_code;
  real best_abs, best_err, a;
  integer trim_ok;
  integer uncal_fail, cal_pass;

  task measure;
    input integer div;
    input real drift;
    input integer osccal;
    input real target;
    begin
      f_osc = F_NOM * (1.0 + drift + STEP_PCT * (osccal - CAL_CODE));
      half_ns = 0.5e9 / f_osc;
      div_n = div;
      divcnt = 0;
      bit_tick = 0;
      @(posedge clk); // let the new period and divider take effect
      t0 = $realtime;
      repeat (32) @(posedge bit_tick);
      t1 = $realtime;
      m_ns = (t1 - t0) / 32.0;
      m_baud = 1.0e9 / m_ns;
      m_err = (m_baud - target) / target * 100.0;
    end
  endtask

  initial begin
    $display("CHIP=attiny85 RC_F_NOM=8MHz TARGET_BAUD=115200 OSCCAL_STEP_PCT=0.5 MIDPOINT_LIM_PCT=%.3f", LIM_PCT);

    // S1: pure integer-cycle divider quantization at zero oscillator error.
    measure(69, 0.0, CAL_CODE, BAUD115);
    $write("MEAS scen=bitbang_quant n69_baud=%.1f n69_err=%.3f", m_baud, m_err);
    measure(70, 0.0, CAL_CODE, BAUD115);
    $display(" n70_baud=%.1f n70_err=%.3f", m_baud, m_err);

    // S2: uncalibrated worst case, best divider (69), against the sampling limit.
    measure(69, 0.10, CAL_CODE, BAUD115);
    ep = m_err;
    measure(69, -0.10, CAL_CODE, BAUD115);
    em = m_err;
    $display("MEAS scen=uncal_worst_115200 plus10_err=%.3f minus10_err=%.3f limit=%.3f fail=%0d",
             ep, em, LIM_PCT,
             ((ep > LIM_PCT || ep < -LIM_PCT) && (em > LIM_PCT || em < -LIM_PCT)) ? 2 : 0);

    // S3: factory-calibrated bounds inside the +/-2% working window.
    measure(69, 0.01, CAL_CODE, BAUD115);
    ep = m_err;
    measure(69, -0.01, CAL_CODE, BAUD115);
    em = m_err;
    $display("MEAS scen=factory_cal_115200 plus1_err=%.3f minus1_err=%.3f pass=%0d",
             ep, em,
             (ep <= 2.0 && ep >= -2.0 && em <= 2.0 && em >= -2.0) ? 2 : 0);

    // S4: full OSCCAL sweep at zero drift; count codes inside each window.
    win2 = 0; winlim = 0;
    for (code = 0; code <= 255; code = code + 1) begin
      measure(69, 0.0, code, BAUD115);
      if (m_err <= 2.0 && m_err >= -2.0) win2 = win2 + 1;
      if (m_err <= LIM_PCT && m_err >= -LIM_PCT) winlim = winlim + 1;
    end
    $display("MEAS scen=osccal_sweep total=256 win2pct=%0d win526=%0d", win2, winlim);

    // S5: can OSCCAL pull a worst-case +/-10% unit back inside +/-2%?
    trim_ok = 0;
    best_code = 0; best_abs = 1.0e9; best_err = 0.0;
    for (code = 0; code <= 255; code = code + 1) begin
      measure(69, 0.10, code, BAUD115);
      a = (m_err < 0.0) ? -m_err : m_err;
      if (a < best_abs) begin best_abs = a; best_code = code; best_err = m_err; end
    end
    $write("MEAS scen=trim_back plus10_code=%0d plus10_res=%.3f", best_code, best_err);
    if (best_err <= 2.0 && best_err >= -2.0) trim_ok = trim_ok + 1;
    best_code = 0; best_abs = 1.0e9; best_err = 0.0;
    for (code = 0; code <= 255; code = code + 1) begin
      measure(69, -0.10, code, BAUD115);
      a = (m_err < 0.0) ? -m_err : m_err;
      if (a < best_abs) begin best_abs = a; best_code = code; best_err = m_err; end
    end
    if (best_err <= 2.0 && best_err >= -2.0) trim_ok = trim_ok + 1;
    $display(" minus10_code=%0d minus10_res=%.3f trim_ok=%0d",
             best_code, best_err, trim_ok);

    // S6: at 9600 the divider quantizes much finer; RC drift is baud-independent.
    measure(833, 0.0, CAL_CODE, BAUD96);
    $write("MEAS scen=baud9600 quant_err=%.3f", m_err);
    measure(833, 0.10, CAL_CODE, BAUD96);
    ep = m_err;
    measure(833, -0.10, CAL_CODE, BAUD96);
    em = m_err;
    measure(833, 0.01, CAL_CODE, BAUD96);
    begin : s6_cal
      real cp, cm;
      cp = m_err;
      measure(833, -0.01, CAL_CODE, BAUD96);
      cm = m_err;
      uncal_fail = ((ep > LIM_PCT || ep < -LIM_PCT) && (em > LIM_PCT || em < -LIM_PCT)) ? 2 : 0;
      cal_pass = (cp <= 2.0 && cp >= -2.0 && cm <= 2.0 && cm >= -2.0) ? 2 : 0;
      $display(" uncal_plus10=%.3f uncal_minus10=%.3f cal_plus1=%.3f cal_minus1=%.3f uncal_fail=%0d cal_pass=%0d",
               ep, em, cp, cm, uncal_fail, cal_pass);
    end

    $display("ATTINY85_BENCH_DONE");
    $finish;
  end
endmodule
