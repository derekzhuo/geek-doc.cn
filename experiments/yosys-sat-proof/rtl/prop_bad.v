module prop_bad(input a, input b, output y1, output y2, output eq);
  // 故意注入错误：第二式把异或写成了与，eq 不再恒成立
  assign y1 = a ^ b;
  assign y2 = ~(a & b);
  assign eq = (y2 == ~y1);
endmodule
