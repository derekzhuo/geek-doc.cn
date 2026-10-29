module broken_integer (
    input  wire [3:0] a,
    output wire [3:0] y
);
    integer i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_bits
            assign y[i] = ~a[i];
        end
    endgenerate
endmodule
