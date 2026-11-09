// Trigger path B: submod.v is read, but the instance names a misspelled
// module 'mull_gate' (double l) that no source file defines.
module top_typo (
    input  wire a,
    input  wire b,
    output wire y
);
    mull_gate u_mul (
        .a(a),
        .b(b),
        .y(y)
    );
endmodule
