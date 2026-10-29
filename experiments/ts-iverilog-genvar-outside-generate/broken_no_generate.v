module broken_no_generate (
    input  wire [3:0] a,
    output wire [3:0] y
);
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin : gen_bits
        assign y[i] = ~a[i];
    end
endmodule
