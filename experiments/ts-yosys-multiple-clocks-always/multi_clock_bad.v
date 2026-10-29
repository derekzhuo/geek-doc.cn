module multi_clock_bad (
    input  wire clk_a,
    input  wire clk_b,
    input  wire d_a,
    input  wire d_b,
    output reg  q_a,
    output reg  q_b
);
    always @(posedge clk_a or posedge clk_b) begin
        q_a <= d_a;
        q_b <= d_b;
    end
endmodule
