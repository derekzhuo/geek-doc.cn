module leaf (
    input wire clk,
    input wire rst,
    input wire [31:0] d,
    output reg [31:0] q
);
always @(posedge clk) begin
    if (rst) q <= 32'b0;
    else q <= (d ^ 32'h13579bdf) + 32'h10203040;
end
endmodule
