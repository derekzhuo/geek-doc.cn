// 真正的 COMBDLY 触发形态：组合 always 块里用非阻塞赋值 <=
module combdly_real(
  input  wire a,
  input  wire b,
  input  wire sel,
  output reg  y
);
  always @(*) begin
    if (sel)
      y <= a;   // 组合逻辑里用 <=，Verilator 报 COMBDLY
    else
      y <= b;
  end
endmodule
