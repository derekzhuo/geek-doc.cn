// 反例：rst_n 一路被当异步复位（negedge 敏感表），
// 另一路又在 always @(posedge clk) 里被当时钟使能同步读取
module syncasync_bad (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q,
    output reg  active
);
  // 用法一：异步复位——rst_n 出现在敏感表的边沿里
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      q <= 1'b0;
    else
      q <= d;
  end

  // 用法二：同步读取——同一 rst_n 又在另一个时序块里被当普通数据采样
  always @(posedge clk) begin
    if (rst_n)          // 把复位信号当时钟使能/状态位来读
      active <= 1'b1;
    else
      active <= 1'b0;
  end
endmodule
