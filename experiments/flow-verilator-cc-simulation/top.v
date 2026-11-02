// 4 位计数器 + 每 16 拍一个分频脉冲
// rst_n 异步低有效复位；q 每个 clk 上升沿加一；q==15 那拍 tick 拉高
module top (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [3:0] q,
    output reg        tick
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q    <= 4'd0;
            tick <= 1'b0;
        end else begin
            q    <= q + 4'd1;
            tick <= (q == 4'd14);
        end
    end
endmodule
