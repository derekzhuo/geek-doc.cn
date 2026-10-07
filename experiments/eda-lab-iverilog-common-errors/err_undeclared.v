// 错误2：未声明标识符——引用了从没声明的信号 tick
module blink (
    input  wire clk,
    output wire led
);
    // tick 从未声明；默认隐式声明被关闭后编译器直接报错
    assign led = tick;
endmodule
