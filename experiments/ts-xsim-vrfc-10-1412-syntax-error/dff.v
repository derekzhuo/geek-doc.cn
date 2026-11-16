`timescale 1ns/1ps

module dff (
    input  wire clk,
    input  wire d,
    output reg  q
);
    always @(posedge clk)
        q <= d;
endmodule
