module optional_repeat #(
    parameter integer EXTRA = 0
) (
    input  wire [7:0] data,
    output wire [(EXTRA == 0 ? 1 : EXTRA) * 8 - 1:0] repeated
);
    generate
        if (EXTRA == 0) begin : g_zero
            // 零次重复：显式给出空结果的边界值，不生成零重复拼接。
            assign repeated = 8'h00;
        end else begin : g_repeat
            assign repeated = {EXTRA{data}};
        end
    endgenerate
endmodule
