// simple_alu.v — 8-bit ALU, 4 ops; LEC + GLS demo target
`timescale 1ns/1ps
module simple_alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [1:0] op,     // 0=add 1=sub 2=and 3=or
    output reg  [7:0] y,
    output wire       zero
);
    always @(*) begin
        case (op)
            2'd0: y = a + b;
            2'd1: y = a - b;
            2'd2: y = a & b;
            default: y = a | b;
        endcase
    end
    assign zero = (y == 8'h00);
endmodule
