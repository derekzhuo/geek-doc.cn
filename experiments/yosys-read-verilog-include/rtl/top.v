// top.v: 顶层模块，include 子目录里的 defs.v
`include "defs.v"

module top (
    input  wire [`DATA_W-1:0] d_in,
    output wire [`DATA_W-1:0] d_out
);
    assign d_out = d_in + `FIFO_DEPTH;
endmodule
