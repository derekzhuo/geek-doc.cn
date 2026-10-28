// 最小复现：用了没定义的宏 BUS_W
module demo_bad(input wire clk, input wire rst_n,
                input wire [`BUS_W-1:0] din,
                output reg [`BUS_W-1:0] dout);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      dout <= {`BUS_W{1'b0}};
    else
      dout <= din;
  end
endmodule
