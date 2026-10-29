module top (
    input  wire oe_n,
    input  wire d,
    output wire q,
    inout  wire pad
);
    assign pad = oe_n ? 1'bz : d;
    assign q = pad;
endmodule
