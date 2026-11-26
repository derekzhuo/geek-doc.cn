`timescale 1ns/1ps
module tb;
  reg clk = 0;
  reg a = 0;
  reg b = 0;
  reg c = 0;
  wire y;
  top dut (.clk(clk), .a(a), .b(b), .c(c), .y(y));
  always #5 clk = ~clk;
  initial begin
    $dumpfile("results/activity.vcd");
    $dumpvars(0, tb);
    #12 a = 1;
    #10 b = 1;
    #8  c = 1;
    #10 a = 0;
    #10 b = 0;
    #8  c = 0;
    #12 a = 1;
    #10 b = 1;
    #10 $finish;
  end
endmodule
