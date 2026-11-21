// 仅用于功能协议仿真；STA 仍读取 teaching.lib。
module DFF_P (
  input  wire D,
  input  wire C,
  output reg  Q
);
  initial Q = 1'b0;
  always @(posedge C)
    Q <= D;
endmodule

module NAND2 (
  input  wire A,
  input  wire B,
  output wire Y
);
  assign Y = ~(A & B);
endmodule
