module multi_driver(input clk, input a, input b, input sel, output reg y);
  always @(posedge clk) y <= sel ? b : a;
endmodule
