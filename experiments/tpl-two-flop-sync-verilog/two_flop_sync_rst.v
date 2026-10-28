// two_flop_sync_rst.v —— 两级触发器同步器（带异步复位版）
module two_flop_sync_rst (
    input  wire clk_dst,
    input  wire rst_n,     // 异步复位，低有效
    input  wire sig_async,
    output wire sig_sync
);
    reg sync_ff1;
    reg sync_ff2;

    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= sig_async;
            sync_ff2 <= sync_ff1;
        end
    end

    assign sig_sync = sync_ff2;
endmodule
