// 4-bit enable-gated counter. The en input is used to reproduce a
// set_input_delay constraint that is missing its -clock reference; the
// fixed XDC anchors the same delay to sys_clk on port clk.
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
