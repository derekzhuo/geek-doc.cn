module adder #(
    parameter W = 4
) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire [W-1:0] y
);
    assign y = a + b;
endmodule
