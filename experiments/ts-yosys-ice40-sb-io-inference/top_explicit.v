module top (
    input  wire oe,
    input  wire d,
    output wire q,
    inout  wire pad
);
    SB_IO #(
        .PIN_TYPE(6'b101001),
        .PULLUP(1'b0),
        .NEG_TRIGGER(1'b0),
        .IO_STANDARD("SB_LVCMOS")
    ) io (
        .PACKAGE_PIN(pad),
        .OUTPUT_ENABLE(oe),
        .D_OUT_0(d),
        .D_IN_0(q)
    );
endmodule
