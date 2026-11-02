`timescale 1ns/1ps
// 4 位带使能、进位输出的递增计数器（回归实验共用 DUT）
module counter4 (
    input  wire       clk,
    input  wire       rst_n,   // 异步复位，低有效
    input  wire       en,      // 高电平使能计数
    output reg  [3:0] q,
    output reg        carry    // q==15 且 en 时拉高一拍
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q     <= 4'd0;
            carry <= 1'b0;
        end else if (en) begin
            q     <= q + 4'd1;
            carry <= (q == 4'd15);
        end else begin
            q     <= q;
            carry <= 1'b0;
        end
    end
endmodule
