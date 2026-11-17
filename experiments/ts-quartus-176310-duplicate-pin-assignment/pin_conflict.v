// Shared design for the Q7 conflicting pin assignment evidence pair.
// Both flows compile this exact module; only the pin location assignments differ.
module pc_top (
    input  wire clk,
    input  wire rst_n,
    output reg  led_a,
    output reg  led_b
);
    reg [23:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 24'd0;
            led_a <= 1'b0;
            led_b <= 1'b0;
        end else begin
            cnt <= cnt + 24'd1;
            if (cnt == 24'd0) begin
                led_a <= ~led_a;
                led_b <= led_a;
            end
        end
    end
endmodule
