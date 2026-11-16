`timescale 1ns/1ps

// Deliberately missing semicolon after the blocking assignment.
module dff_bad (
    input  wire clk,
    input  wire d,
    output reg  q
);
    always @(posedge clk)
        q <= d
endmodule
