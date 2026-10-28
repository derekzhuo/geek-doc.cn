module initdly_fixed (
    input  wire clk,
    output reg  rst_n,
    output reg  init_done
);
  reg [3:0] cnt;
  initial begin
    cnt       = 4'd0;
    rst_n     = 1'b0;
    init_done = 1'b0;
  end
  always @(posedge clk) begin
    if (cnt < 4'd10)
      cnt <= cnt + 4'd1;
    if (cnt == 4'd9)
      rst_n <= 1'b1;        // 第 10 个时钟沿释放复位
    if (cnt == 4'd10)
      init_done <= 1'b1;    // 再晚一拍置位完成标志
  end
endmodule
