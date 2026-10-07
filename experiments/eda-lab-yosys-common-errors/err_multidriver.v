// 错误 2：同一个 reg 被两个 always 块驱动（多驱动）
// 触发：read_verilog 能过，proc/synth 阶段报 multiple drivers
module dual_drive (
    input  wire clk_a,
    input  wire clk_b,
    input  wire rst_n,
    output reg  cnt
);
    // 两个 always 块都在给 cnt 赋值 —— 硬件上不存在这种结构
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) cnt <= 1'b0;
        else        cnt <= ~cnt;
    end

    always @(posedge clk_b) begin
        cnt <= 1'b1;
    end
endmodule
