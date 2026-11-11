module top(input clk, input rst, output reg led);
always @(posedge clk)
  if (rst) led <= 1'b0;
  else led <= ~led;
endmodule
