// uart_rx.v —— 串口接收器（含 FSM），供 yosys synth 流程拆解实验使用
// 3 倍过采样版本：CLKS_PER_BIT 参数控制每位占用的时钟数（实验取 16）
// 状态机：IDLE -> START -> DATA -> STOP -> CLEANUP -> IDLE
module uart_rx #(
    parameter CLKS_PER_BIT = 16
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rxd,        // 串行输入（空闲为高）
    output reg  [7:0] data,       // 接收到的字节
    output reg        data_valid  // 一个字节接收完成，单拍脉冲
);

    localparam [2:0] IDLE    = 3'd0;
    localparam [2:0] START   = 3'd1;
    localparam [2:0] DATA    = 3'd2;
    localparam [2:0] STOP    = 3'd3;
    localparam [2:0] CLEANUP = 3'd4;

    reg [2:0] state;
    reg [7:0] clk_cnt;                  // 位内时钟计数
    reg [2:0] bit_idx;                  // 已收比特序号 0..7
    reg [7:0] shift;                    // 移位寄存器
    reg       rxd_sync, rxd_sync_d;     // 两级同步器

    // 输入同步，消除亚稳态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_sync   <= 1'b1;
            rxd_sync_d <= 1'b1;
        end else begin
            rxd_sync   <= rxd;
            rxd_sync_d <= rxd_sync;
        end
    end

    // 状态机 + 数据通路
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            clk_cnt    <= 8'd0;
            bit_idx    <= 3'd0;
            shift      <= 8'd0;
            data       <= 8'd0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;          // 默认拉低，单拍脉冲
            case (state)
                IDLE: begin
                    clk_cnt <= 8'd0;
                    bit_idx <= 3'd0;
                    if (rxd_sync_d == 1'b0)      // 检测到起始位下降沿
                        state <= START;
                end

                START: begin
                    // 等半个位周期，在起始位中点确认仍为低
                    if (clk_cnt == (CLKS_PER_BIT - 1) / 2) begin
                        if (rxd_sync_d == 1'b0) begin
                            clk_cnt <= 8'd0;
                            state   <= DATA;
                        end else begin
                            state   <= IDLE;     // 毛刺，放弃
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 8'd1;
                    end
                end

                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt          <= 8'd0;
                        shift[bit_idx]   <= rxd_sync_d;  // 在比特中点采样
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 8'd1;
                    end
                end

                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        data       <= shift;
                        data_valid <= 1'b1;
                        clk_cnt    <= 8'd0;
                        state      <= CLEANUP;
                    end else begin
                        clk_cnt <= clk_cnt + 8'd1;
                    end
                end

                CLEANUP: begin
                    state <= IDLE;
                end

                default: state <= state;
            endcase
        end
    end

endmodule
