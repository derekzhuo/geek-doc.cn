// baud_tick.v -- 波特率节拍发生器（历史模块，已随多代产品流片）
// 从 50 MHz 输入时钟分频出 115200  Baud 的单周期节拍。
module baud_tick (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg        tick
);
    // 50e6 / 115200 ~= 434，计数到 433 拉一个周期
    localparam [15:0] DIV = 16'd434;
    reg [15:0] cnt;

    // 历史调试遗留：翻转脉冲只给逻辑分析仪用，模块内没有任何消费者
    wire dbg_toggle;
    assign dbg_toggle = (cnt == 16'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 16'd0;
            tick <= 1'b0;
        end else if (en) begin
            if (cnt == DIV - 16'd1) begin
                cnt  <= 16'd0;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 16'd1;
                tick <= 1'b0;
            end
        end else begin
            cnt  <= 16'd0;
            tick <= 1'b0;
        end
    end
endmodule
