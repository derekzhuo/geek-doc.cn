// latch_fixed.v —— 补全 else 分支，组合逻辑在所有路径都有赋值
module latch_fixed (
    input  wire sel,
    input  wire a,
    input  wire b,
    output reg  y
);
  always @(*) begin
    if (sel)
      y = a;
    else
      y = b;   // 补全分支：任何输入组合下 y 都有确定值
  end
endmodule
