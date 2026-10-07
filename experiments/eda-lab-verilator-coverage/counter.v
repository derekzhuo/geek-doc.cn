// counter.v — 8 位带使能/同步清零/溢出标志的计数器
// 用于演示 Verilator line/toggle 覆盖率收集
`timescale 1ns/1ps
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       clr,
    output reg  [7:0] count,
    output reg        ovf
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'd0;
            ovf   <= 1'b0;
        end else if (clr) begin
            count <= 8'd0;
            ovf   <= 1'b0;
        end else if (en) begin
            count <= count + 8'd1;
            if (count == 8'hFF) begin
                ovf <= 1'b1;
            end
        end
    end
endmodule
