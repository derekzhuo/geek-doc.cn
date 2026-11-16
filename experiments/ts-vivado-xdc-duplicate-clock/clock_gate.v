// 4-bit enable-gated counter. The only clock port is named clk; the bad
// XDC defines two clocks on that same port to reproduce duplicate-clock
// constraint behavior in Vivado 2017.4 non-project batch mode.
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
