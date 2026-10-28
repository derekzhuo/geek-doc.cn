// UART 发送器：8N1，约 60 个 cell 量级
module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data,
    input  wire       start,
    output reg        txd
);
    parameter BAUD_DIV = 16'd868;   // 100MHz / 115200

    reg [15:0] baud_cnt;
    reg [3:0]  bit_cnt;
    reg [9:0]  shift;
    reg        busy;

    wire baud_tick = (baud_cnt == BAUD_DIV - 1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_cnt <= 16'd0;
            bit_cnt  <= 4'd0;
            shift    <= 10'h3ff;
            busy     <= 1'b0;
            txd      <= 1'b1;
        end else begin
            if (start && !busy) begin
                shift    <= {1'b1, data, 1'b0};
                busy     <= 1'b1;
                bit_cnt  <= 4'd0;
                baud_cnt <= 16'd0;
            end else if (busy) begin
                if (baud_tick) begin
                    baud_cnt <= 16'd0;
                    txd      <= shift[0];
                    shift    <= {1'b1, shift[9:1]};
                    bit_cnt  <= bit_cnt + 4'd1;
                    if (bit_cnt == 4'd9)
                        busy <= 1'b0;
                end else begin
                    baud_cnt <= baud_cnt + 16'd1;
                end
            end
        end
    end
endmodule
