// edge_detector.v —— 可综合 RTL：同步上升沿检测（时序逻辑）
// 配套 fpga/beginner/04-testbench-simulation.md。
// 把输入 sig 打一拍得到 sig_d，当 sig=1 且上一拍 sig_d=0 时输出一个时钟周期的高脉冲。
// 用途：按键/信号的上升沿捕获、脉冲展宽的逆操作等。
module edge_detector (
    input  wire clk,
    input  wire rst_n,     // 低有效复位
    input  wire sig,       // 待检测的异步/同步输入
    output wire rise_pulse // 检测到上升沿时拉高一个时钟周期
);
    reg sig_d;             // sig 打一拍

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sig_d <= 1'b0;
        else
            sig_d <= sig;
    end

    // 本拍为 1、上拍为 0 => 上升沿
    assign rise_pulse = sig & ~sig_d;
endmodule
