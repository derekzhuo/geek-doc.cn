// LFSR/PRBS 模板：Galois（多输入型）与 Fibonacci（抽头型）两种结构
// WIDTH 位宽，TAPS 为 Galois 反馈掩码（如 PRBS7 多项式 x^7+x^6+1 -> 8'hC1）
module lfsr_galois #(
    parameter int WIDTH = 7,
    parameter logic [WIDTH-1:0] TAPS = 8'hC1
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  enable,
    input  wire [WIDTH-1:0]      seed,
    input  wire                  load,
    output logic [WIDTH-1:0]     state,
    output wire                  bit_out
);
    assign bit_out = state[0];   // Galois 通常取最低位串行输出
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= '0;
        else if (load)
            state <= seed;
        else if (enable) begin
            if (state[0])
                state <= (state >> 1) ^ TAPS;
            else
                state <= (state >> 1);
        end
    end
endmodule

// Fibonacci（外部异或型）：右移，抽头位异或后反馈到最高位
// 右移约定下 PRBS7 多项式 x^7+x^6+1 的抽头掩码 TAP_MASK=7'h03（bit0 与 bit1）
module lfsr_fibonacci #(
    parameter int WIDTH = 7,
    parameter logic [WIDTH-1:0] TAP_MASK = 7'h03
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  enable,
    input  wire [WIDTH-1:0]      seed,
    input  wire                  load,
    output logic [WIDTH-1:0]     state,
    output wire                  bit_out
);
    logic feedback;
    assign bit_out  = state[0];           // 与 Galois 一致从最低位取流
    assign feedback = ^(state & TAP_MASK);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= '0;
        else if (load)
            state <= seed;
        else if (enable)
            state <= {feedback, state[WIDTH-1:1]};
    end
endmodule
