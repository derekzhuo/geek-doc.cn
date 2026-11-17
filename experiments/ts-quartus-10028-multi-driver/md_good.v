// Fixed version: the force_off override is merged into the single
// always block that owns led, so the register has exactly one driver.
module md_top (
    input  wire clk,
    input  wire rst_n,
    input  wire force_off,
    output reg  led
);
    reg [23:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 24'd0;
            led <= 1'b0;
        end else begin
            cnt <= cnt + 24'd1;
            if (force_off)
                led <= 1'b0;
            else if (cnt == 24'd0)
                led <= ~led;
        end
    end
endmodule
