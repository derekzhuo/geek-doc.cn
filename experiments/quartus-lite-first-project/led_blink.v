// Quartus Lite 25.1 首个工程：LED 闪烁（分频计数器）
// EP4CE6E22C8（Cyclone IV E），50MHz 时钟下约 0.67s 翻转一次
module led_blink (
    input  wire clk,
    input  wire rst_n,
    output reg  led
);
    reg [24:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 25'd0;
            led <= 1'b0;
        end else begin
            cnt <= cnt + 25'd1;
            if (cnt == 25'd25_000_000 - 1) begin
                cnt <= 25'd0;
                led <= ~led;
            end
        end
    end
endmodule
