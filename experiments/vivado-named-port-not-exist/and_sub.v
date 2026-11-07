// Two-port submodule instantiated by both the bad and fixed tops.
module and_sub (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = a & b;
endmodule
