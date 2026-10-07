// counter.v —— 32 位计数器（verilator --binary 速度对比实验被测设计）
// 功能：同步复位、使能计数，32 位自然回绕。
// 注意：只要任一模块带 timescale，其余模块也必须有，否则 verilator 报 TIMESCALEMOD
`timescale 1ns/1ps

module counter (
    input  wire        clk,    // 时钟
    input  wire        rst_n,  // 低有效同步复位
    input  wire        en,     // 计数使能
    output reg  [31:0] count   // 32 位计数值
);

    always @(posedge clk) begin
        if (!rst_n)
            count <= 32'd0;
        else if (en)
            count <= count + 32'd1;
        // en 为 0 时保持
    end

endmodule
