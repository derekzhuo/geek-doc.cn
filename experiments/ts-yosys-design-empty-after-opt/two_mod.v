module orphan(input a, output y);
  assign y = ~a;
endmodule

module top(input a, input b, output y);
  assign y = a & b;
endmodule
