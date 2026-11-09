// Same logic with the missing semicolon restored: synthesis completes cleanly.
module syntax_fixed (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire y,
    output wire z
);
    assign y = a & b;
    assign z = y | c;
endmodule
