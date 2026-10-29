module unsigned_broken (
    input  wire        [7:0] count,
    input  wire signed [7:0] delta,
    output wire              underflow
);
    assign underflow = (count + delta) < 0;
endmodule
