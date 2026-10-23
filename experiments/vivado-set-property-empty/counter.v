module counter(input clk, output reg [3:0] led);
  always @(posedge clk) led <= led + 1;
endmodule
