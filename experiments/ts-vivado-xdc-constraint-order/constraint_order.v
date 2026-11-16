// Four-bit enable-gated counter. The en port receives conflicting
// IOSTANDARD values from two XDC files; the last read constraint survives.
module constraint_order (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [3:0] cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'd0;
        else if (en)
            cnt <= cnt + 4'd1;
    end
endmodule
