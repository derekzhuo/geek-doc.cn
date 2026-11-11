module counter(input clk, input rst, output reg [3:0] q);
always @(posedge clk)
  if (rst) q <= 4'd0;
  else q <= q + 4'd1;
endmodule
