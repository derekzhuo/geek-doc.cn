module alwcomborder_fixed (
    input  logic a,
    input  logic b,
    output logic y
);
    logic tmp;

    always_comb begin
        tmp = a & b;    // 先写 tmp
        y   = tmp;      // 再读 tmp，消费本轮刚计算出的值
    end
endmodule
