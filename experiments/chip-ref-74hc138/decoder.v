`timescale 1ns/1ps
module decoder_74hc138 (
    input  wire       g1,
    input  wire       g2a_n,
    input  wire       g2b_n,
    input  wire [2:0] a,
    output reg  [7:0] y_n
);
    always @* begin
        if (g1 && !g2a_n && !g2b_n)
            y_n = ~(8'b0000_0001 << a);
        else
            y_n = 8'hff;
    end
endmodule
