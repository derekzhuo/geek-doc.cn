// 备选修复：重叠是「有意的优先级译码」时，改用 priority case 显式声明意图
module irq_prio (
    input  wire [3:0] irq,
    output reg  [1:0] vec
);
    always @(*) begin
        priority case (1'b1)
            irq[0]: vec = 2'd0;
            irq[1]: vec = 2'd1;   // irq 多位同时为 1 时，靠前者优先，重叠是有意的
            irq[2]: vec = 2'd2;
            irq[3]: vec = 2'd3;
            default: vec = 2'd0;
        endcase
    end
endmodule
