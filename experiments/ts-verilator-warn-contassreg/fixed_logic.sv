module fixed_logic (
    input  logic a,
    output logic y
);
    logic q;

    assign q = a;
    assign y = q;
endmodule
