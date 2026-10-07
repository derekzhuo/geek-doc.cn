// UART 发送 FSM：IDLE -> START -> DATA -> STOP
// 16 倍过采样计数 0..15，用 oversample==4'd15 作为位边界
module baud_tx_fsm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick,        // 来自 baud_clk_div 的 16x tick
    input  wire       tx_start,    // 上层请求发送一个字节
    input  wire [7:0] tx_data,
    input  wire       last,        // 来自 baud_bit_cnt：当前位是最后一位
    output reg        tx,          // UART 串行输出线
    output reg        inc,         // 位计数器 +1
    output reg        clr,         // 位计数器清零
    output reg        busy
);
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] oversample;   // 0..15
    reg [7:0] shreg;

    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= IDLE;
            oversample <= 4'd0;
            shreg      <= 8'd0;
            tx         <= 1'b1;   // UART 空闲为高
            inc        <= 1'b0;
            clr        <= 1'b0;
            busy       <= 1'b0;
        end else begin
            inc <= 1'b0;
            clr <= 1'b0;
            case (state)
                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (tx_start) begin
                        shreg      <= tx_data;
                        oversample <= 4'd0;
                        clr        <= 1'b1;
                        busy       <= 1'b1;
                        state      <= START;
                    end
                end
                START: begin
                    tx <= 1'b0;   // 起始位拉低
                    if (tick) begin
                        if (oversample == 4'd15) begin
                            oversample <= 4'd0;
                            state      <= DATA;
                        end else
                            oversample <= oversample + 4'd1;
                    end
                end
                DATA: begin
                    tx <= shreg[0];
                    if (tick) begin
                        if (oversample == 4'd15) begin
                            oversample <= 4'd0;
                            shreg      <= {1'b0, shreg[7:1]};
                            inc        <= 1'b1;
                            if (last)
                                state <= STOP;
                        end else
                            oversample <= oversample + 4'd1;
                    end
                end
                STOP: begin
                    tx <= 1'b1;   // 停止位拉高
                    if (tick && oversample == 4'd15)
                        state <= IDLE;
                    else if (tick)
                        oversample <= oversample + 4'd1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
