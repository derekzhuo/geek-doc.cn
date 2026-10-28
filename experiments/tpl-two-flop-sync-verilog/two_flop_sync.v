// two_flop_sync.v —— 单比特 CDC 两级触发器同步器（基本版，无复位）
module two_flop_sync (
    input  wire clk_dst,   // 目标时钟域时钟
    input  wire sig_async, // 异步输入信号
    output wire sig_sync   // 同步后的信号
);
    reg sync_ff1;
    reg sync_ff2;

    always @(posedge clk_dst) begin
        sync_ff1 <= sig_async;
        sync_ff2 <= sync_ff1;
    end

    assign sig_sync = sync_ff2;
endmodule
