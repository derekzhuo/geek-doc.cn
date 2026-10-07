// 修复版对照：四类问题全部修正后的干净设计
// ① 信号全部显式声明（配合 default_nettype none 也通过）
// ② cnt 只有一个 always 块驱动
// ③ 用 read_verilog -sv 读入（logic/always_ff 合法）
// ④ 组合环用寄存器打断
`default_nettype none
module ok_fixed (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output wire led,
    output wire y
);
    wire tick;
    wire en;
    reg  cnt;

    assign en   = 1'b1;
    assign tick = clk & rst_n;
    assign led  = tick & en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 1'b0;
        else        cnt <= ~cnt;
    end

    // 原组合环：a = sel ? d : b; b = a;  —— 用寄存器把环打断
    reg b_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) b_q <= 1'b0;
        else        b_q <= d;
    end
    assign y = b_q;
endmodule
`default_nettype wire
