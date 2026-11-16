module bank_probe (
    input  wire clk,
    input  wire a,
    input  wire b,
    output reg  y
);
    always @(posedge clk) begin
        y <= a & b;
    end
endmodule
