// BAD: one always block sensitive to two clock edges with an internal select.
// Vivado synthesis emits [Synth 8-91] ambiguous clock in event control.
module ambclk_bad (
    input  wire clk1,
    input  wire clk2,
    input  wire sel,
    input  wire d1,
    input  wire d2,
    output reg  q
);
    always @(posedge clk1 or posedge clk2) begin
        if (sel)
            q <= d1;
        else
            q <= d2;
    end
endmodule
