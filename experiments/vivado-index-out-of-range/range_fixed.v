// FIXED: select the MSB inside the declared range.
module range_fixed (
    input  wire       clk,
    input  wire [3:0] a,
    output reg        y
);
    always @(posedge clk) begin
        y <= a[3];
    end
endmodule
