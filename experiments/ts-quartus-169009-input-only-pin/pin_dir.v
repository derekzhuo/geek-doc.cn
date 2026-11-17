// Shared design for the Q5 pin-direction conflict evidence pair.
// Both flows compile this exact module; only the led pin location differs.
module pd_top (
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
            if (cnt == 24'd0)
                led <= ~led;
        end
    end
endmodule
