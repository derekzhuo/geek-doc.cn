// alu8: 极简 8 位 ALU，作为回归脚本演示用 DUT
module alu8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [1:0] op,     // 0: add, 1: sub, 2: and, 3: or
    output reg  [7:0] y
);
    always @(*) begin
        case (op)
            2'd0: y = a + b;
            2'd1: y = a - b;
            2'd2: y = a & b;
            default: y = a | b;
        endcase
    end
endmodule
