`timescale 1ns/1ps
module counter4 (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [3:0] count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) count <= 4'd0;
        else        count <= count + 4'd1;
    end
endmodule
