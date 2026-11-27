`timescale 1ns/1ps

module dut_toggle (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [1:0] cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 2'd0;
        else
            cnt <= cnt + 2'd1;
    end
endmodule
