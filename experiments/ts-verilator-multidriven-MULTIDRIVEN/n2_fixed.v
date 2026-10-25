module n2_fixed(input wire clk, input wire sel, input wire a, input wire b, output reg y);
  always @(posedge clk) y <= sel ? a : b;   // 合并到单一时钟域、单一驱动源
endmodule
