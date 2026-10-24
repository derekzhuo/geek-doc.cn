// Single-bit two-flop synchronizer.
module sync_2ff (
    input  wire clk,
    input  wire rst_n,
    input  wire d_async,
    output wire q_sync
);
    reg meta, sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            meta <= 1'b0;
            sync <= 1'b0;
        end else begin
            meta <= d_async;
            sync <= meta;
        end
    end
    assign q_sync = sync;
endmodule
