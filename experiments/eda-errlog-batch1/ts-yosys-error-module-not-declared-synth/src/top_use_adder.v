module top_use_adder(input [3:0] a, input [3:0] b, output [4:0] y);
  sub_adder u_add(.a(a), .b(b), .y(y));
endmodule
