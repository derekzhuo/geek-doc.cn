// Flip-flop divide-by-2 clock divider followed by a register clocked from
// the divided clock. Without a create_generated_clock constraint, the
// clk_div domain has no clock object and its timing paths are unconstrained.
module clock_div (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    reg clk_div;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div <= 1'b0;
        else
            clk_div <= ~clk_div;
    end

    always @(posedge clk_div or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule
