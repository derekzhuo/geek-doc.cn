// multi_drv_fixed.v —— 修复版：一个 always 块内用选择信号决定 y 的来源
module multi_drv_fixed (
    input  wire clk,
    input  wire rst_n,
    input  wire sel,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] y
);
  // 唯一驱动源：时序 always，块内用 sel 表达「到底要 a 还是 b」的意图
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      y <= 8'h00;
    else if (sel)
      y <= b;
    else
      y <= a;
  end
endmodule
