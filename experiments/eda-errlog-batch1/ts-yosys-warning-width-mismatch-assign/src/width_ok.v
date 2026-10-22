module width_ok(input [3:0] a, output [7:0] y);
  assign y = {4'b0000, a};  // 显式零扩展
endmodule
