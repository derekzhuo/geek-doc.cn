// Structural multi-driver: one wire driven by both a continuous assignment
// and a submodule instance output.
module net_bad (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire y
);
    assign y = a & b;

    and_sub u_and (
        .a(c),
        .b(a),
        .y(y)
    );
endmodule
