module fixed_logic (
    input  logic a,
    output logic y
);
    always_comb begin
        y = a;
    end
endmodule
