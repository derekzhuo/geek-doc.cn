// Latch inferred from an incomplete case in a combinational always block:
// sel == 2'b10 / 2'b11 leave y unassigned, so y must keep its old value.
module latch_case_bad (
    input  wire [1:0] sel,
    input  wire       a,
    input  wire       b,
    output reg        y
);
    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b01: y = b;
        endcase
    end
endmodule
