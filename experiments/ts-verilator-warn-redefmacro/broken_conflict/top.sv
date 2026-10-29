`include "common.vh"
`define DATA_W 16

module top (
    input  wire [`DATA_W-1:0] in,
    output wire [`DATA_W-1:0] out
);
    assign out = in;
endmodule
