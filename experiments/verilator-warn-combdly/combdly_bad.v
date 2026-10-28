// 组合 always 块里写 # 延时：仿真器里模拟门延迟的惯用写法
module combdly_bad(
  input  wire a,
  input  wire b,
  input  wire sel,
  output reg  y
);
  always @(*) begin
    if (sel)
      #5 y = a;   // 组合逻辑里的 intra-assignment 延时
    else
      #5 y = b;
  end
endmodule
