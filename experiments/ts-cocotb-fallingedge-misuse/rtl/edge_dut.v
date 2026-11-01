// 最小 DUT：低有效复位同步寄存器 + 一根组合逻辑输出
// 供 cocotb 边沿触发器误用实验使用
`timescale 1ns/1ps
module edge_dut #(
    parameter WIDTH = 4
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             din_v,
    input  wire [WIDTH-1:0] din,
    output wire             comb_gate,
    output reg  [WIDTH-1:0] dout,
    output reg              busy
);

    // 纯组合逻辑：输入稳定时它永远不跳变，无法产生任何边沿事件
    assign comb_gate = din_v & rst_n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {WIDTH{1'b0}};
            busy <= 1'b0;
        end else if (din_v) begin
            dout <= din;
            busy <= 1'b1;
        end else begin
            busy <= 1'b0;
        end
    end

endmodule
