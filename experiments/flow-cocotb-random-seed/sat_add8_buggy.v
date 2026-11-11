// Boundary-bug variant: comparison is off by one (>= 256 written as > 256),
// so total == 256 wraps to 0 instead of saturating. Kept for the demo only.
module sat_add8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       sat
);
    wire [8:0] total = {1'b0, a} + {1'b0, b};

    assign sat = (total > 9'd256);
    assign sum = sat ? 8'd255 : total[7:0];
endmodule
