// 顶层：波特率发生器 + 位计数器 + 发送 FSM
module baud_top #(
    parameter DIV = 27
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx,
    output wire       busy
);
    wire       tick;
    wire       inc, clr;
    wire [2:0] bit_idx;
    wire       last;

    baud_clk_div #(.DIV(DIV)) u_div (
        .clk   (clk),
        .rst_n (rst_n),
        .tick  (tick)
    );

    baud_bit_cnt u_bitcnt (
        .clk     (clk),
        .rst_n   (rst_n),
        .inc     (inc),
        .clr     (clr),
        .bit_idx (bit_idx),
        .last    (last)
    );

    baud_tx_fsm u_fsm (
        .clk      (clk),
        .rst_n    (rst_n),
        .tick     (tick),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .last     (last),
        .tx       (tx),
        .inc      (inc),
        .clr      (clr),
        .busy     (busy)
    );
endmodule
