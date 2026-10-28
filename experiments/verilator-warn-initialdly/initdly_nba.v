module initdly_nba (
    input  wire clk,
    output reg  rst_n
);
  initial begin
    rst_n = 1'b0;
    rst_n <= #10 1'b1;   // 带延时的非阻塞赋值：期望 10 时间单位后生效
  end
endmodule
