module prop_good(input a, input b, output y1, output y2, output eq);
  assign y1 = a ^ b;
  assign y2 = ~(a ^ b);
  assign eq = (y2 == ~y1);
endmodule
