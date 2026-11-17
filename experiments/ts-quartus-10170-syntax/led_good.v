// Minimal valid Cyclone IV design: reset blink counter.
module led_blink (
    input  wire clk,
    input  wire rst_n,
    output reg  led
);
    reg [23:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 24'd0;
            led <= 1'b0;
        end else begin
            cnt <= cnt + 24'd1;
            led <= cnt[23];
        end
    end
endmodule
