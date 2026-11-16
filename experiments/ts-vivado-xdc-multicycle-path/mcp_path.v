// Two-stage pipeline on a single 10 ns clock. The path stage_reg -> q_reg
// is a normal single-cycle path by default; a set_multicycle_path constraint
// changes its setup requirement from one clock period to two.
module mcp_path (
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    reg stage;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage <= 1'b0;
        else
            stage <= d;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= stage;
    end
endmodule
