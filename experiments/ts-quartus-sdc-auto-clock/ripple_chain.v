module ripple_chain (
    input wire clk,
    input wire a,
    input wire b,
    input wire [63:0] mask,
    output reg y
);
    reg a_reg;
    reg b_reg;
    reg [63:0] mask_reg;
    wire [64:0] chain;
    assign chain[0] = a_reg;
    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin : g_chain
            assign chain[i + 1] = chain[i] ^ (b_reg & mask_reg[i]);
        end
    endgenerate
    always @(posedge clk) begin
        a_reg <= a;
        b_reg <= b;
        mask_reg <= mask;
        y <= chain[64];
    end
endmodule
