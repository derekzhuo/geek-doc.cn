module alwcomborder_bad (
    input  logic a,
    input  logic b,
    output logic y
);
    logic tmp;

    always_comb begin
        y   = tmp;      // 先读 tmp：此时本块尚未给它本轮的新值
        tmp = a & b;    // 后写 tmp：触发 ALWCOMBORDER
    end
endmodule
