`timescale 1ns/1ps
// 8 位带使能计数器：异步复位清零，en=1 时上升沿加一，计到 255 时 carry 拉高一拍
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [7:0] q,
    output wire       carry
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'd0;
        else if (en)
            q <= q + 8'd1;
    end

    assign carry = en & (q == 8'd255);
endmodule
