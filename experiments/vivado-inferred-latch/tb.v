`timescale 1ns/1ps
module tb;
  reg a = 0, b = 0; wire y;
  latch_demo dut(.a(a), .b(b), .y(y));
  initial begin
    #10 b = 1; #10 a = 1;  #10 b = 0; #10 a = 0;
    #10 $display("a=%b b=%b y=%b (a拉低后y应保持)", a, b, y);
    #10 $finish;
  end
endmodule
