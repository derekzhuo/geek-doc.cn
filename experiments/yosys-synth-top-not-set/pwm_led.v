// PWM 调光 LED 输出
module pwm_led (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] duty,
    output reg        pwm
);
    reg [7:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'd0;
            pwm <= 1'b0;
        end else begin
            cnt <= cnt + 8'd1;
            pwm <= (cnt < duty);
        end
    end
endmodule
