// 顶层：SoC 风格小设计，例化 uart_tx / pwm_led / debounce 三个子模块
module chip_top (
    input  wire clk,
    input  wire rst_n,
    input  wire btn,
    input  wire [7:0] tx_data,
    input  wire tx_start,
    output wire txd,
    output wire led
);
    wire btn_clean;

    debounce u_debounce (
        .clk (clk),
        .rst_n(rst_n),
        .din (btn),
        .dout(btn_clean)
    );

    uart_tx u_uart_tx (
        .clk   (clk),
        .rst_n (rst_n),
        .data  (tx_data),
        .start (tx_start & btn_clean),
        .txd   (txd)
    );

    pwm_led u_pwm_led (
        .clk (clk),
        .rst_n(rst_n),
        .duty(tx_data),
        .pwm (led)
    );
endmodule
