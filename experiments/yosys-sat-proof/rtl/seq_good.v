module seq_good(input clk, output [3:0] q1, output [3:0] q2, output eq);
  reg [3:0] a, b;
  initial begin a = 4'd0; b = 4'd0; end
  always @(posedge clk) a <= a + 4'd1;
  always @(posedge clk) b <= b + 4'd1;
  assign q1 = a;
  assign q2 = b;
  assign eq = (a == b);
endmodule
