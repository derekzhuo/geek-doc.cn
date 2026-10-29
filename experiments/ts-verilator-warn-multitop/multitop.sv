module chip_top (
    input  logic [1:0] a,
    input  logic [1:0] b,
    output logic [2:0] sum
);
    assign sum = a + b;
endmodule

module debug_top (
    input  logic [7:0] sample,
    output logic       parity
);
    assign parity = ^sample;
endmodule
