module pipeline (
    input wire clk,
    input wire rst_n,
    input wire d,
    output reg q
);
reg stage_reg;
always @(posedge clk) begin
    if (!rst_n) begin
        stage_reg <= 1'b0;
        q <= 1'b0;
    end else begin
        stage_reg <= d;
        q <= stage_reg;
    end
end
endmodule
