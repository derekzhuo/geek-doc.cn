// adder.v —— 8 位加法器
module adder (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [8:0] sum
);
    assign sum = a + b;
endmodule
