`timescale 1ns/1ps
module tb_ts;
  reg clk = 0;
  reg [7:0] d = 8'd0;
  wire [7:0] q;
  dut u(.clk(clk), .d(d), .q(q));
  always #5 clk = ~clk;
  initial begin
    #12 d = 8'hA5;
    #20 d = 8'h3C;
    #30 $finish;
  end
endmodule
