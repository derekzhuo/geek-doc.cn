module latch_demo(input a, input b, output reg y);
  always @(*) if (a) y = b;
endmodule
