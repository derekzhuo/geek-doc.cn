// 波特率分频器：把系统时钟分到 16 倍波特率的 tick
// 50 MHz / 16 / 115200 ≈ 27.1，取 DIV=27 时误差约 0.5%
module baud_clk_div #(
    parameter DIV = 27
) (
    input  wire       clk,
    input  wire       rst_n,
    output reg        tick
);
    reg [4:0] cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt  <= 5'd0;
            tick <= 1'b0;
        end else if (cnt == DIV-1) begin
            cnt  <= 5'd0;
            tick <= 1'b1;
        end else begin
            cnt  <= cnt + 5'd1;
            tick <= 1'b0;
        end
    end
endmodule
