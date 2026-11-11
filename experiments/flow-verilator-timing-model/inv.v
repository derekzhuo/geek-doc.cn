`timescale 1ns/1ps
// 最小 DUT：反相器，输出带 1ns 惯性延时
module inv(input wire a, output wire y);
  assign #1 y = ~a;
endmodule
