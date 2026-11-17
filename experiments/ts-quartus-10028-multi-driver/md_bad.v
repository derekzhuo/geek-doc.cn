// Same blink design with a deliberate multi-driver defect: the register
// "led" is assigned from two separate always blocks. Quartus reports
// Error (10028): Can't resolve multiple constant drivers for net "led".
module md_top (
    input  wire clk,
    input  wire rst_n,
    input  wire force_off,
    output reg  led
);
    reg [23:0] cnt;

    // Blink process: toggles led each time the counter wraps.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 24'd0;
            led <= 1'b0;
        end else begin
            cnt <= cnt + 24'd1;
            if (cnt == 24'd0)
                led <= ~led;
        end
    end

    // Override process written as a second driver on the same register.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            led <= 1'b0;
        else if (force_off)
            led <= 1'b0;
    end
endmodule
