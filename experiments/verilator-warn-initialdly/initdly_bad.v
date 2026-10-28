module initdly_bad (
    input  wire clk,
    output reg  rst_n,
    output reg  init_done
);
  initial begin
    rst_n     = 1'b0;
    init_done = 1'b0;
    #10 rst_n     = 1'b1;   // 期望：延时 10 时间单位后释放复位
    #5  init_done = 1'b1;   // 期望：再过 5 时间单位置位完成标志
  end
endmodule
