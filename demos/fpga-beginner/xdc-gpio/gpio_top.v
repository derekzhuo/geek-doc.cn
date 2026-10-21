// gpio_top.v —— 可综合 RTL：拨动开关直连 LED + 一颗心跳灯
// 配套 fpga/beginner/05-xdc-constraints-intro.md。
// 用途：把「管脚约束」要绑的几种端口凑齐——时钟、复位按键、拨码开关输入、LED 输出。
//   - sw[7:0] 直连 led[7:0]：拨哪个开关哪个灯亮（纯组合/直通，方便肉眼核对管脚对错）
//   - 按键 btn 作为高有效复位；100MHz 时钟分频出约 1Hz 心跳，驱动 led[15]
// 约束见 basys3.xdc（Digilent Basys3 / Artix-7 XC7A35T 真实管脚，其它板子照自己 master XDC 改）。
module gpio_top #(
    parameter integer CLK_FREQ = 100_000_000  // Basys3 板载 100MHz
) (
    input  wire        clk,      // 100MHz 单端时钟
    input  wire        btn,      // 一个按键：高有效复位（按下=1）
    input  wire [7:0]  sw,       // 8 位拨码开关
    output reg  [15:0] led       // 16 颗 LED
);
    // 心跳：数到半周期(0.5s)翻转一次 -> 1Hz
    localparam integer HALF = CLK_FREQ / 2;
    localparam integer CNT_W = 27;           // 100e6/2 = 5e7 < 2^26，给 27 位
    reg [CNT_W-1:0] cnt;
    reg heartbeat;

    always @(posedge clk) begin
        if (btn) begin                       // 按键按下即复位（高有效）
            cnt       <= 0;
            heartbeat <= 1'b0;
        end else if (cnt == HALF - 1) begin
            cnt       <= 0;
            heartbeat <= ~heartbeat;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    // 低 8 位 LED 跟随开关；bit[15] 给心跳灯；其余位关断
    always @(*) begin
        led[7:0]   = sw;
        led[14:8]  = 7'b0;
        led[15]    = heartbeat;
    end
endmodule
