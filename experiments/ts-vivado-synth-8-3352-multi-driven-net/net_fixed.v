// Single-driver fix: the instance output lands on an internal wire, and one
// continuous assignment selects between the two sources.
module net_fixed (
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire sel,
    output wire y
);
    wire sub_y;

    and_sub u_and (
        .a(c),
        .b(a),
        .y(sub_y)
    );

    assign y = sel ? sub_y : (a & b);
endmodule
