module latch_demo(input a, input b, output reg y);
  always @(*) begin
    if (a) y = b; else y = 1'b0;
  end
endmodule
