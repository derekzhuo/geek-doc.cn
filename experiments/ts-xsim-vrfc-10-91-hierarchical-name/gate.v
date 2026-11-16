`timescale 1ns/1ps

module gate (
    input  wire a,
    input  wire b,
    output wire y
);
    wire internal_and;

    assign internal_and = a & b;
    assign y = internal_and;
endmodule
