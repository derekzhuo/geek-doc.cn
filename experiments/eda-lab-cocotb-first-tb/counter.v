// counter.v —— 4 位计数器（被测设计 DUT）
// 与 el-iverilog-first-sim 是同一颗计数器，额外加了一个溢出脉冲输出 ovf，
// 方便 cocotb 篇演示「计数值 + 标志位」两类断言。
module counter (
    input  wire       clk,
    input  wire       rst_n,  // 低有效同步复位
    input  wire       en,     // 计数使能
    output reg  [3:0] count,
    output reg        ovf     // 溢出脉冲：en=1 且 count==15 的下一拍拉高一个周期
);
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 4'd0;
            ovf   <= 1'b0;
        end else if (en) begin
            count <= count + 4'd1;
            ovf   <= (count == 4'd15);
        end else begin
            ovf   <= 1'b0;
        end
    end
endmodule
