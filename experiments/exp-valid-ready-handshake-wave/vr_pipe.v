// Simple valid-ready pipeline stage (one-deep elastic buffer).
module vr_pipe #(
    parameter DW = 8
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          in_valid,
    output wire          in_ready,
    input  wire [DW-1:0] in_data,
    output reg           out_valid,
    input  wire          out_ready,
    output reg  [DW-1:0] out_data
);
    assign in_ready = !out_valid || out_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= 0;
        end else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid) out_data <= in_data;
        end
    end
endmodule
