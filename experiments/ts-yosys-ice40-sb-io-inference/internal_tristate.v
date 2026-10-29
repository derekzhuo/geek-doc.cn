module top (
    input  wire oe,
    input  wire d,
    output wire q
);
    wire internal_bus;
    assign internal_bus = oe ? d : 1'bz;
    assign q = ~internal_bus;
endmodule
