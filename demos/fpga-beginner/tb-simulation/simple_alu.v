// simple_alu.v —— 可综合 RTL：一个极简 8 位 ALU
// 配套 fpga/beginner/04-testbench-simulation.md，用来给 testbench 当「被测对象(DUT)」。
// 功能：按 op 对 a/b 做与/或/加/减，输出结果 y 与标志 zero(z)/进位或借位(carry)。
// 故意写得简单、行为确定，方便在 testbench 里手算期望值做自检。
module simple_alu (
    input  wire [7:0] a,      // 操作数 A
    input  wire [7:0] b,      // 操作数 B
    input  wire [1:0] op,     // 00=AND 01=OR 10=ADD 11=SUB(a-b)
    output reg  [7:0] y,      // 结果
    output reg        z,      // zero 标志：y==0 时为 1
    output reg        carry   // ADD: 进位；SUB: 借位(a<b 时为 1)
);
    // 用 9 位临时量保存加法/减法结果，bit[8] 即进位/借位
    reg [8:0] result_w;

    always @(*) begin
        result_w = 9'b0;
        case (op)
            2'b00: begin
                y       = a & b;
                carry   = 1'b0;
            end
            2'b01: begin
                y       = a | b;
                carry   = 1'b0;
            end
            2'b10: begin                       // ADD
                result_w = a + b;
                y        = result_w[7:0];
                carry    = result_w[8];        // 有进位
            end
            2'b11: begin                       // SUB a - b
                result_w = a - b;
                y        = result_w[7:0];
                carry    = result_w[8];        // a<b 时产生借位
            end
        endcase
        z = (y == 8'b0) ? 1'b1 : 1'b0;
    end
endmodule
