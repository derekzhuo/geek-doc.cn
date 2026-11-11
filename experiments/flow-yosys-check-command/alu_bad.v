// 故意埋了两个结构性错误的教学用例：
//   1) 位宽不匹配：b 为 5 位，a+b 结果为 5 位，却连进 4 位的 sum（静默截断）
//   2) 多驱动：y 同时被一个时序 always 块和一个组合 always 块赋值
module alu_bad (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [3:0] a,
    input  wire [4:0] b,
    output reg  [3:0] y,
    output wire [3:0] sum
);
  // 错误 1：右侧最大位宽 5，左侧只有 4
  assign sum = a + b;

  // 错误 2a：时序块驱动 y
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      y <= 4'd0;
    else if (en)
      y <= a;
  end

  // 错误 2b：组合块也驱动 y —— 一张网挂了两个驱动源
  always @(*) begin
    y = sum;
  end
endmodule
