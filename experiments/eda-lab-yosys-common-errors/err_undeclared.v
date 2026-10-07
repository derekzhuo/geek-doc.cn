// 错误 1：default_nettype none 下使用未声明的线网
// 触发：read_verilog 阶段直接报错
`default_nettype none
module blink (
    input  wire clk,
    input  wire rst_n,
    output wire led
);
    // tick 从未声明；default_nettype none 禁止隐式线网
    assign led  = tick & en;
    assign tick = clk & rst_n;
endmodule
`default_nettype wire
