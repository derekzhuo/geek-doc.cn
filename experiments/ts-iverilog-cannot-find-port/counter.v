module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    output reg  [3:0] count
);
  always @(posedge clk) begin
    if (!rst_n)
      count <= 4'd0;
    else if (enable)
      count <= count + 1'b1;
  end
endmodule
