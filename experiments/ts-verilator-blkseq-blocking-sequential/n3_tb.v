`timescale 1ns/1ps
module n3_tb;
  reg clk = 0, d = 0;
  wire q1b, q2b, q1f, q2f;
  n3_bad   ub(.clk(clk), .d(d), .q1(q1b), .q2(q2b));
  n3_fixed uf(.clk(clk), .d(d), .q1(q1f), .q2(q2f));
  always #5 clk = ~clk;
  initial begin
    $dumpfile("n3_wave.vcd");
    $dumpvars(0, n3_tb);
    #3 d = 1;
    #40 d = 0;
    #20 $finish;
  end
endmodule
