// antenna_wide.v — 32 位宽、256 级打包移位寄存器链（8192 个触发器）
// 用打包宽寄存器整体移位实现，避开旧版 Verilator 对数组元素循环 NBA 的限制；
// 用于在 RT_MAX_LAYER 限层条件下拉长 clk/rst_n/en 脊柱走线，观察天线违例报告。
`default_nettype none
module antenna_wide #(
    parameter integer W = 32,
    parameter integer D = 256
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              en,
    input  wire [W-1:0]      d,
    output wire [W-1:0]      q
);
    reg [W*D-1:0] chain;

    always @(posedge clk) begin
        if (!rst_n)
            chain <= {(W*D){1'b0}};
        else if (en)
            chain <= {chain[W*D-1-W:0], d};
    end

    assign q = chain[W*D-1:W*(D-1)];
endmodule
`default_nettype wire
