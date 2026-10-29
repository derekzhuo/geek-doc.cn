`timescale 1ns/1ps
module max485 (
    input  wire di,
    input  wire de,
    input  wire re_n,
    output wire ro,
    inout  wire a,
    inout  wire b
);
    wire received = (a === 1'b1 && b === 1'b0) ? 1'b1 :
                    (a === 1'b0 && b === 1'b1) ? 1'b0 : 1'bx;
    assign a = de ? di : 1'bz;
    assign b = de ? ~di : 1'bz;
    assign ro = re_n ? 1'bz : received;
endmodule
