module top (
    input  logic in_data,
    output logic out_data
);
    /* verilator lint_off PINCONNECTEMPTY */
    child u_child (
        .in_data  (in_data),
        .in_valid (),
        .out_data (out_data)
    );
    /* verilator lint_on PINCONNECTEMPTY */
endmodule
