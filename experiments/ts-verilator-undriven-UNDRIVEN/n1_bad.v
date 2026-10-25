module n1_bad(input wire a, output wire y);
  wire u;        // 声明了但没有任何驱动
  assign y = u & a;
endmodule
