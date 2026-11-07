// FIXED: only the two real formal ports a and b are connected.
module port_fixed (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire y
);
    and_sub u_and (
        .a (a),
        .b (b),
        .y (y)
    );

    // c is intentionally unused in this minimal reproducer.
    wire unused_c = c;
endmodule
