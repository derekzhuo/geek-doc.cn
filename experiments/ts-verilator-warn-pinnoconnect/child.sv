module child (
    input  logic in_data,
    input  logic in_valid,
    output logic out_data
);
    always_comb begin
        out_data = in_data & in_valid;
    end
endmodule
