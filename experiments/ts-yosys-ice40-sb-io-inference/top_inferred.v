module top (
    input  wire oe,
    input  wire d,
    output wire q,
    inout  wire pad
);
    assign pad = oe ? d : 1'bz;
    assign q = pad;
endmodule
