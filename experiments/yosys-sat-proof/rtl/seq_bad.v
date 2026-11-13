module seq_bad(input clk, output [3:0] q1, output [3:0] q2, output eq);
  reg [3:0] a, b;
  initial begin a = 4'd0; b = 4'd0; end
  // 故意注入错误：第二个计数器每拍加 2，一拍之后两值发散
  always @(posedge clk) a <= a + 4'd1;
  always @(posedge clk) b <= b + 4'd2;
  assign q1 = a;
  assign q2 = b;
  assign eq = (a == b);
endmodule
