module multi_driver(input clk, input a, input b, output reg y);
  always @(posedge clk) y <= a;
  always @(posedge clk) y <= b;
endmodule
