// 最小复现：复位分支用 =、累加分支用 <=，同一变量 cnt 混用两种赋值
module blkandnblk_bad(
  input  wire       clk,
  input  wire       rst_n,
  output reg  [7:0] cnt
);
  always @(posedge clk) begin
    if (!rst_n)
      cnt = 8'd0;      // 复位分支误用阻塞赋值
    else
      cnt <= cnt + 1;  // 主逻辑用非阻塞赋值
  end
endmodule
