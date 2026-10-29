module multi_clock_fixed (
    input  wire clk_a,
    input  wire clk_b,
    input  wire d_a,
    input  wire d_b,
    output reg  q_a,
    output reg  q_b
);
    always @(posedge clk_a) begin
        q_a <= d_a;
    end

    always @(posedge clk_b) begin
        q_b <= d_b;
    end
endmodule
