// blink_top: 27-bit counter, upper nibble drives 4 LEDs (Arty A7-35T, xc7a35tcsg324-1)
module blink_top (
    input  wire       clk,
    output wire [3:0] led
);
    reg [26:0] cnt = 27'd0;
    always @(posedge clk) cnt <= cnt + 1'b1;
    assign led = cnt[26:23];
endmodule
