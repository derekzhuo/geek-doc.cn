module counter8(input clk, input rst_n, output reg [7:0] q);
  always @(posedge clk or negedge rst_n)
    if (!rst_n) q <= 8'd0;
    else q <= q + 8'd1;
endmodule
