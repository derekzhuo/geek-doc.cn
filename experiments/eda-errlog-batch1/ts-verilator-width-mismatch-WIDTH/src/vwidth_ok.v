module vwidth_ok(input [3:0] a, output reg [11:0] y);
  always @(*) y = {8'b0, a};
endmodule
