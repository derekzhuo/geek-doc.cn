`timescale 1ns/1ps
// 最小可综合设计：4 位带使能的递增计数器
// rst_n 异步低有效复位；en=1 时每个时钟上升沿加 1；计到 15 且 en=1 时 carry 拉高
module counter4 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [3:0] q,
    output wire       carry
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'd0;
        else if (en)
            q <= q + 4'd1;
    end

    assign carry = (q == 4'd15) & en;
endmodule
