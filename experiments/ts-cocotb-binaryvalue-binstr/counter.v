`timescale 1ns/1ps
module counter (
    input  wire       clk,
    output reg  [7:0] data
);
    initial data = 8'b0;
    always @(posedge clk) begin
        data <= data + 1'b1;
    end
endmodule
