module latch_fixed (
    input  wire en,
    input  wire d,
    output reg  q
);
always @(*) begin
    if (en)
        q = d;
    else
        q = 1'b0;
end
endmodule
