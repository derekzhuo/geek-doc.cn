// 重构残留场景：WIDTH 正在用，MAX_DEPTH 与 DEBUG_LEVEL 声明后无人引用
module unusedparam_bad #(
    parameter WIDTH       = 8,     // 在用
    parameter MAX_DEPTH   = 16,    // 重构后残留，没人引用了
    parameter DEBUG_LEVEL = 2      // 调试占位参数，从未接线
)(
    input  wire             clk,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule
