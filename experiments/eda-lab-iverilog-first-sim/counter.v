// counter.v —— 4 位计数器（iverilog 仿真入门实验被测设计）
// 功能：同步复位、使能计数，溢出自然回绕。
module counter (
    input  wire       clk,    // 时钟
    input  wire       rst_n,  // 低有效同步复位
    input  wire       en,     // 计数使能
    output reg  [3:0] count   // 4 位计数值
);

    always @(posedge clk) begin
        if (!rst_n)
            count <= 4'd0;
        else if (en)
            count <= count + 4'd1;
        // en 为 0 时保持
    end

endmodule
