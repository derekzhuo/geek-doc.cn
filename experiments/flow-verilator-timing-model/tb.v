`timescale 1ns/1ps
module tb;
  reg a;
  wire y;
  inv u_inv(.a(a), .y(y));
  initial begin
    a = 1'b0;
    #2 $display("t=%0t a=%b y=%b", $time, a, y);
    #2 a = 1'b1;
    #2 $display("t=%0t a=%b y=%b", $time, a, y);
    #2 a = 1'b0;
    #2 $display("t=%0t a=%b y=%b", $time, a, y);
    #2 $finish;
  end
endmodule
