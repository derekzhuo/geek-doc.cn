module blinky_delay (
    input  wire clk,
    output reg  led
);

    // 事件驱动仿真器里完全合法的写法：上电 10ns 后把 led 拉高
    initial begin
        led = 1'b0;

         #10 led = 1'b1;   // ← Verilator 报 STMTDLY 的位置
    end

endmodule
