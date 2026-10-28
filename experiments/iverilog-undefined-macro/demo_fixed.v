// 修复版：先 include 宏定义文件，再使用宏
`include "defs.vh"
module demo_fixed(input wire clk, input wire rst_n,
                  input wire [`BUS_W-1:0] din,
                  output reg [`BUS_W-1:0] dout);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      dout <= `RST_VAL;
    else
      dout <= din;
  end
endmodule
