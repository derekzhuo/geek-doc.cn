`timescale 1ns/1ps
// 8 位 ALU：加 / 减 / 与 / 或
module alu (
    input  wire [1:0] op,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] y
);
    always @(*) begin
        case (op)
            2'b00: y = a + b;
            2'b01: y = a - b;
            2'b10: y = a & b;
            default: y = a | b;
        endcase
    end
endmodule