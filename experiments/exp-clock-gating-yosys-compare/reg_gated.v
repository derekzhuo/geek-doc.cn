// Style B: explicit AND-gated clock (what an ICG cell does, modeled as a gate).
// Same function as reg_en, but the enable cuts the clock net instead of
// muxing data back into the flop.
module reg_gated (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [7:0] d,
    output reg  [7:0] q
);
    wire gclk = clk & en;   // simplified ICG model
    always @(posedge gclk or negedge rst_n) begin
        if (!rst_n) q <= 8'd0;
        else        q <= d;
    end
endmodule
