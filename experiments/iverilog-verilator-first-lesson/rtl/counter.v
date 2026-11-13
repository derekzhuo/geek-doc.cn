// 最小可综合设计：带使能与同步复位的 4 位计数器。
// 同一份 RTL 分别交给 Icarus Verilog 与 Verilator 仿真，
// 用来对照事件驱动仿真与周期级编译仿真的差异。
module counter #(
    parameter WIDTH = 4
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             enable,
    output reg [WIDTH-1:0]  count
);
    always @(posedge clk) begin
        if (!rst_n)
            count <= {WIDTH{1'b0}};
        else if (enable)
            count <= count + 1'b1;
    end
endmodule
