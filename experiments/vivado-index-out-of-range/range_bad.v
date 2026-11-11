// BAD: constant bit select index 5 is outside the declared [3:0] vector.
// Vivado synthesis emits [Synth 8-27] ... out of range.
module range_bad (
    input  wire       clk,
    input  wire [3:0] a,
    output reg        y
);
    always @(posedge clk) begin
        y <= a[5];
    end
endmodule
