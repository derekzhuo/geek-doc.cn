`timescale 1ns/1ps

module tb_resolution;

  reg  clk;
  wire q;

  dut_clock u_dut (
    .clk(clk),
    .q(q)
  );

  initial begin
    clk = 1'b0;
    #10;
    $display("TIMESCALE_SIM_TIME %0t q=%0b", $time, q);
    $finish;
  end

endmodule
