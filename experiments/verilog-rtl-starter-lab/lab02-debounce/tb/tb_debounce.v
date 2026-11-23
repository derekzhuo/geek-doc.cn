`timescale 1ns/1ps

module tb_debounce;
  integer errors = 0;
`include "tb_tasks.vh"

  reg  clk = 0;
  reg  rst_n;
  reg  noisy;
  wire db_level;
  wire db_pulse;

  always #5 clk = ~clk;

  debounce #(.N(4)) dut (
    .clk(clk), .rst_n(rst_n), .noisy(noisy),
    .db_level(db_level), .db_pulse(db_pulse)
  );

  integer pulses = 0;
  always @(posedge clk) begin
    if (db_pulse) pulses = pulses + 1;
  end

  initial begin
    $dumpfile("lab02-debounce/sim_build/lab02.vcd");
    $dumpvars(0, tb_debounce);

    rst_n = 0;
    noisy = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    // Mechanical bounce: three quick 0->1->1->0 bursts, none stable.
    repeat (3) begin
      @(posedge clk) noisy = 1;
      @(posedge clk) noisy = 0;
    end
    repeat (8) @(posedge clk);
    check_input(db_level == 1'b0, "glitches do not change debounced level");
    check_input(pulses == 0, "glitches produce no press pulse");

    // Stable press: level must latch and exactly one pulse fires.
    noisy = 1;
    repeat (6) @(posedge clk);
    check_input(db_level == 1'b1, "stable press latches debounced level");
    check_input(pulses == 1, "exactly one press pulse for one press");

    // Stable release.
    noisy = 0;
    repeat (6) @(posedge clk);
    check_input(db_level == 1'b0, "stable release clears debounced level");
    check_input(pulses == 1, "release generates no extra pulse");

    finish_summary(errors);
  end
endmodule
