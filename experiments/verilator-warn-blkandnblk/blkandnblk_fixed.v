// 修复版：同一变量 cnt 全量统一为非阻塞赋值 <=
module blkandnblk_fixed(
  input  wire       clk,
  input  wire       rst_n,
  output reg  [7:0] cnt
);
  always @(posedge clk) begin
    if (!rst_n)
      cnt <= 8'd0;     // 复位同样用 <=
    else
      cnt <= cnt + 1;
  end
endmodule
