module add2 (
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [2:0] s
);
    assign s = a + b;
endmodule
