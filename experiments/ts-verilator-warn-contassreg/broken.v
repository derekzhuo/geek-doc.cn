module broken (
    input  wire a,
    output wire y
);
    reg q;

    assign q = a;
    assign y = q;
endmodule
