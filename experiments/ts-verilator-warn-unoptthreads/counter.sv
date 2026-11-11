module counter #(
    parameter logic [31:0] OFFSET = 0
) (
    input  logic clk,
    input  logic [31:0] seed,
    output logic [31:0] count
);
    always_ff @(posedge clk) count <= count + seed + OFFSET;
endmodule
