`include "common.vh"
`include "regs.vh"

module top (
    input  wire [`DATA_W-1:0] in,
    output wire [`DATA_W-1:0] out
);
    assign out = in;
endmodule
