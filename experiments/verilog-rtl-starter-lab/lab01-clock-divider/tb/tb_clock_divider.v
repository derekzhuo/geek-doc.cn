`timescale 1ns/1ps

module tb_clock_divider;
  integer errors = 0;
`include "tb_tasks.vh"

  reg  clk = 0;
  reg  rst_n;
  wire out;

  always #5 clk = ~clk;  // 100 MHz test clock, 10 ns period

  clock_divider #(.DIV(4)) dut (
    .clk(clk), .rst_n(rst_n), .out(out)
  );

  integer cycles = 0;
  always @(posedge clk) cycles = cycles + 1;

  integer prev_cycles;
  integer period_cycles;
  integer i;

  initial begin
    $dumpfile("lab01-clock-divider/sim_build/lab01.vcd");
    $dumpvars(0, tb_clock_divider);

    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    // Measure three consecutive toggle periods in input-clock cycles.
    // With DIV=4, out must toggle (either edge) once every 4 input clocks.
    @(out);
    #1 prev_cycles = cycles;
    for (i = 0; i < 3; i = i + 1) begin
      @(out);
      #1 period_cycles = cycles - prev_cycles;
      check_input(period_cycles == 4, "out toggles once every DIV input clocks");
      prev_cycles = cycles;
    end

    check_input(out === 1'b0 || out === 1'b1, "out stays a resolved logic level");
    finish_summary(errors);
  end
endmodule
