// Same mux intent with a default branch: every path assigns y, so the logic
// stays purely combinational and no latch primitive is inferred.
module latch_case_fixed (
    input  wire [1:0] sel,
    input  wire       a,
    input  wire       b,
    output reg        y
);
    always @(*) begin
        case (sel)
            2'b00:   y = a;
            2'b01:   y = b;
            default: y = 1'b0;
        endcase
    end
endmodule
