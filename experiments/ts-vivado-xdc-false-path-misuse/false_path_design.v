// Two-stage pipeline on one clock. stage_reg -> q_reg is a real functional
// path that must meet setup timing unless a deliberate timing exception applies.
module false_path_design (
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
