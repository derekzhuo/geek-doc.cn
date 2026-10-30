module top (
    input  logic in_data,
    output logic out_data
);
    child u_child (
        .in_data  (in_data),
        .out_data (out_data)
    );
endmodule
