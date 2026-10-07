// 位计数器：数当前字节已经发到第几位（0-7）
module baud_bit_cnt (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       inc,      // 每发完一位拉高一个 tick
    input  wire       clr,      // 新字节开始时清零
    output reg  [2:0] bit_idx,
    output wire       last      // 当前是最后一位
);
    always @(posedge clk) begin
        if (!rst_n)
            bit_idx <= 3'd0;
        else if (clr)
            bit_idx <= 3'd0;
        else if (inc)
            bit_idx <= bit_idx + 3'd1;
    end

    assign last = (bit_idx == 3'd7);
endmodule
