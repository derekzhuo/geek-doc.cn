`timescale 1ns/1ps
// 对照实验：事件驱动仿真器（iverilog）里 #5 延迟真实生效
module tb_delay;
    reg  a, b;
    wire y;

    assign #5 y = a & b;

    initial begin
        $monitor("t=%0t a=%b b=%b y=%b", $time, a, b, y);
        a = 0; b = 0;
        #10 a = 1; b = 1;   // t=10 输入拉高
        #10 a = 0; b = 0;
        #10 $finish;
    end
endmodule
