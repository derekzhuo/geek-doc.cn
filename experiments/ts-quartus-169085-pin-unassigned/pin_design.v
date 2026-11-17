// Shared design for the Q4 warning-boundary evidence pair.
// Both flows compile this exact module; only the QSF pin assignments differ.
module pp_top (
    input  wire       clk,
    input  wire       rst_n,
    output reg [3:0]  led
);
    reg [23:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 24'd0;
            led <= 4'b0000;
        end else begin
            cnt <= cnt + 24'd1;
            if (cnt == 24'd0)
                led <= led + 4'd1;
        end
    end
endmodule
