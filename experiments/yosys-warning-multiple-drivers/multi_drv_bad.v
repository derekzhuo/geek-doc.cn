// multi_drv_bad.v —— 多驱动复现用例：两个 always 块同时驱动同一个 reg
module multi_drv_bad (
    input  wire clk,
    input  wire rst_n,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] y
);
  // 驱动源 1：时序逻辑，复位时清零，否则锁存 a
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      y <= 8'h00;
    else
      y <= a;
  end

  // 驱动源 2：组合逻辑，也想驱动 y —— 与上面那个 always 块冲突
  always @(*) begin
    y = b;
  end
endmodule
