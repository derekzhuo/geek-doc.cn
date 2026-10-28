// 修复：组合逻辑里改用阻塞赋值 =
module combdly_real_fixed(
  input  wire a,
  input  wire b,
  input  wire sel,
  output reg  y
);
  always @(*) begin
    if (sel)
      y = a;    // 组合逻辑用阻塞赋值
    else
      y = b;
  end
endmodule
