`timescale 1ns/1ps
// led_blink_tb.v —— testbench（不可综合，仅仿真）
// 用小参数加速：把时钟设成 100MHz、翻转间隔设成 5 个周期，波形很快能看到 LED 翻转。
module led_blink_tb;
    reg  clk;
    reg  rst_n;
    wire led;

    // CLK_FREQ=100、BLINK_HZ=10 => TOGGLE_CNT = 100/(2*10) = 5，每 5 个周期翻转一次
    led_blink #(.CLK_FREQ(100), .BLINK_HZ(10)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .led(led)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;   // 周期 10ns => 100MHz

    initial begin
        rst_n = 1'b0;       // 先复位
        #23  rst_n = 1'b1;  // 释放复位
        #300 $finish;       // 跑够看到几次翻转就结束
    end

    initial begin
        $monitor("time=%0t  rst_n=%b  led=%b", $time, rst_n, led);
        $dumpfile("led_blink_tb.vcd");   // 生成波形，gtkwave 打开
        $dumpvars(0, led_blink_tb);
    end
endmodule
