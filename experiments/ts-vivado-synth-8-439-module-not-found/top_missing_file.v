// Trigger path A: the tcl script forgets to read submod.v, so mul_gate is
// never added to the synthesis project even though the instance name is right.
module top_missing_file (
    input  wire a,
    input  wire b,
    output wire y
);
    mul_gate u_mul (
        .a(a),
        .b(b),
        .y(y)
    );
endmodule
