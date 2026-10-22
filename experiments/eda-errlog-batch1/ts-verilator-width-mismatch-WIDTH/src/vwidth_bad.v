module vwidth_bad(input [3:0] a, output reg [11:0] y);
  always @(*) y = a;  // 12 = 4，触发 %Warning-WIDTH
endmodule
