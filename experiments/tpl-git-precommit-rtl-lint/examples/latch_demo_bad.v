module latch_demo (
    input  wire en,
    input  wire d,
    output reg  q
);
always @(*) begin
    if (en) q = d;
end
endmodule
