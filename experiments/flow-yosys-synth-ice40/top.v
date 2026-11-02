// 最小 iCE40 设计：24 位计数器，最高 4 位直接驱动板载 LED
// 12 MHz 时钟下，led[0] 翻转频率约 12e6/2^21 ~= 5.7 Hz，肉眼可见
module top (
    input  wire       clk,     // 12 MHz 板载晶振，iCEstick 引脚 21
    input  wire       rst_n,   // 低有效复位，接扩展排针引脚 8
    output wire [3:0] led      // 4 颗板载 LED，引脚 99/98/97/96
);
    reg [23:0] q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 24'd0;
        else
            q <= q + 24'd1;
    end

    assign led = q[23:20];
endmodule
