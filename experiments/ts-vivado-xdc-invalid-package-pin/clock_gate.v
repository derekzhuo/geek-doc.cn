// 4-bit enable-gated counter on xc7a35t (Basys 3 package cpg236). The bad
// XDC assigns a package pin that does not exist on this package; the fixed
// XDC uses the real Basys 3 clock pin E3.
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
