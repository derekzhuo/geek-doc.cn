module fixed_wire (
    input  wire a,
    output wire y
);
    wire q;

    assign q = a;
    assign y = q;
endmodule
