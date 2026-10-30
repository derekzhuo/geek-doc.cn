module top (
    input  logic in_data,
    input  logic in_valid,
    output logic out_data
);
    child u_child (
        .in_data  (in_data),
        .in_valid (in_valid),
        .out_data (out_data)
    );
endmodule
