// two_flop_sync_edge.v —— 两级同步 + 上升沿检测（异步脉冲变目标域单周期脉冲）
module two_flop_sync_edge (
    input  wire clk_dst,
    input  wire rst_n,
    input  wire sig_async,
    output wire sig_pulse  // 上升沿检测，输出一个 clk_dst 周期的脉冲
);
    reg sync_ff1;
    reg sync_ff2;
    reg sync_ff3;

    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
            sync_ff3 <= 1'b0;
        end else begin
            sync_ff1 <= sig_async;
            sync_ff2 <= sync_ff1;
            sync_ff3 <= sync_ff2;
        end
    end

    assign sig_pulse = sync_ff2 & ~sync_ff3;
endmodule
