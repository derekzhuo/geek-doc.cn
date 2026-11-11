`timescale 1ns/1ps
module counter4 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [3:0] q,
    output wire       carry
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)      q <= 4'd0;
    else if (en)     q <= q + 4'd1;
  end
  assign carry = (q == 4'd15) & en;
endmodule
