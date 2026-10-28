// 修复版：删掉没人用的 MAX_DEPTH / DEBUG_LEVEL，接口只保留真实在用的 WIDTH
module unusedparam_fixed #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule
