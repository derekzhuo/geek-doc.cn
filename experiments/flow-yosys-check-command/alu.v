// 修复版：
//   1) a、b 统一 4 位，和拓宽到 5 位的 sum，不截断
//   2) y 只有一个时序驱动块，en=0 时在块内选择 sum
module alu (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [3:0] y,
    output wire [4:0] sum
);
  assign sum = a + b;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      y <= 4'd0;
    else if (en)
      y <= a;
    else
      y <= sum[3:0];
  end
endmodule
