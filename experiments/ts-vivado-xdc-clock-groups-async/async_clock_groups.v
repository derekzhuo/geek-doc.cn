// Data crosses from clk_a domain stage_reg to clk_b domain q_reg.
// Without an async exception Vivado times the crossing; set_clock_groups
// declares the two clocks asynchronous and cuts inter-clock timing checks.
module async_clock_groups (
    input  wire clk_a,
    input  wire clk_b,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    reg stage;

    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n)
            stage <= 1'b0;
        else
            stage <= d;
    end

    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= stage;
    end
endmodule
