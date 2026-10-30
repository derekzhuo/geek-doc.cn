module named (
    input  logic a,
    input  logic b,
    output logic y
);
    generate
        if (1) begin : g_select
            logic selected;
            assign selected = a & b;
            assign y = selected;
        end
    endgenerate
endmodule
