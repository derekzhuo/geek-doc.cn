// latch_bad.v —— always @(*) 分支不全，y 在 sel 为假时没有被赋值
module latch_bad (
    input  wire sel,
    input  wire a,
    output reg  y
);
  always @(*) begin
    if (sel)
      y = a;
    // 缺少 else 分支：sel==0 时 y 保持旧值 → 推断出 latch
  end
endmodule
