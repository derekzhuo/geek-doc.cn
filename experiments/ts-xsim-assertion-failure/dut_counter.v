// 4-bit enable counter with async reset; wraps 0..15 by design.
`timescale 1ns/1ps
module dut_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [3:0] cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'd0;
        else if (en)
            cnt <= cnt + 4'd1;
    end
endmodule
