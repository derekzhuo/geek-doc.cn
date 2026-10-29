module unsigned_fixed (
    input  wire        [7:0] count,
    input  wire signed [7:0] delta,
    output wire              underflow
);
    wire signed [8:0] signed_count = {1'b0, count};
    wire signed [8:0] signed_delta = {delta[7], delta};

    assign underflow = (signed_count + signed_delta) < 9'sd0;
endmodule
