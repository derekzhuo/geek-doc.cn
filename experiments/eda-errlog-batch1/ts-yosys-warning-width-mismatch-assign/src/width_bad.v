module width_bad(input [3:0] a, output [7:0] y);
  assign y = a;  // 隐式零扩展：8 = 4 位宽差
endmodule
