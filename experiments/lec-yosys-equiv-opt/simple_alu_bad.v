// simple_alu_bad.v — BUG: sub implemented as a-b-1 (one-off error)
module simple_alu_bad (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [1:0] op,
    output reg  [7:0] y,
    output wire       zero
);
    always @(*) begin
        case (op)
            2'd0: y = a + b;
            2'd1: y = a - b - 8'd1;   // BUG
            2'd2: y = a & b;
            default: y = a | b;
        endcase
    end
    assign zero = (y == 8'h00);
endmodule
