// led_blink.v —— FPGA 入门第一个工程：LED 闪烁（时钟分频 + 计数器）
// 可综合 RTL，Vivado/Quartus 通用。时钟与 LED 管脚见 constraints.xdc。
module led_blink #(
    parameter integer CLK_FREQ = 50_000_000,  // 输入时钟频率（Hz），按板载晶振改
    parameter integer BLINK_HZ = 1            // LED 闪烁频率（Hz）
)(
    input  wire clk,     // 系统时钟
    input  wire rst_n,   // 复位，低电平有效（按开发板按键极性调整）
    output reg  led      // LED 输出
);
    // 每半个闪烁周期翻转一次 LED => 计数终值 = CLK_FREQ / (2*BLINK_HZ)
    localparam integer TOGGLE_CNT = CLK_FREQ / (2 * BLINK_HZ);
    localparam integer CNT_W     = 26;        // 足够覆盖 50MHz/2 的计数位宽

    reg [CNT_W-1:0] cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            cnt <= 0;
            led <= 1'b0;
        end else if (cnt == TOGGLE_CNT - 1) begin
            cnt <= 0;
            led <= ~led;   // 计到点就翻转 LED
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule
