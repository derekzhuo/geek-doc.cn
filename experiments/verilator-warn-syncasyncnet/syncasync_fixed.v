// 修复：同步/异步拆成两路——rst_n 专职异步复位；
// 需要同步读到的「复位状态」先经同步器打拍成 rst_n_sync，再被采样
module syncasync_fixed (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q,
    output reg  active
);
  reg rst_ff1, rst_n_sync;

  // 复位同步器：异步释放前的毛刺与时钟域对齐，两级触发器打拍
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rst_ff1    <= 1'b0;
      rst_n_sync <= 1'b0;
    end else begin
      rst_ff1    <= 1'b1;
      rst_n_sync <= rst_ff1;
    end
  end

  // rst_n 只走异步复位这一条路
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      q <= 1'b0;
    else
      q <= d;
  end

  // 同步侧只读打拍后的 rst_n_sync，不再碰原始 rst_n
  always @(posedge clk) begin
    if (rst_n_sync)
      active <= 1'b1;
    else
      active <= 1'b0;
  end
endmodule
