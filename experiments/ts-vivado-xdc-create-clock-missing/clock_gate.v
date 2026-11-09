// Enable-gated 4-bit counter. The clock port is named clk; the bad XDC
// references a port named clkk that does not exist on this module.
module clock_gate (
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
