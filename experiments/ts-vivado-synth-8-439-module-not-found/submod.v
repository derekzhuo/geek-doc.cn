// Two-input AND submodule referenced by all three top-level designs.
module mul_gate (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = a & b;
endmodule
