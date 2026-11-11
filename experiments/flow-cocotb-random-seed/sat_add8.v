// 8-bit saturating adder: sum = min(a + b, 255), sat flags clamping.
module sat_add8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       sat
);
    wire [8:0] total = {1'b0, a} + {1'b0, b};

    assign sat = (total > 9'd255);
    assign sum = sat ? 8'd255 : total[7:0];
endmodule
