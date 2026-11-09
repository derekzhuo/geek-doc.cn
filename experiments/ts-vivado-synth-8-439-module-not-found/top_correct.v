// Fixed top: submod.v is read and the module name matches the definition.
module top_correct (
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
