module dut_counter(
  input  wire clk,
  input  wire rst_n,
  output reg [3:0] q
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= 4'd0;
    else q <= q + 4'd1;
  end
endmodule
