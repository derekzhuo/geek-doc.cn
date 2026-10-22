`timescale 1ns/1ps
module fifo16x8 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire [7:0] din,
    output reg  [7:0] dout,
    output wire       full,
    output wire       empty,
    output wire       almost_full,
    output wire       almost_empty
);
    reg [7:0] mem [0:15];
    reg [3:0] wr_ptr = 0, rd_ptr = 0;
    reg [4:0] cnt = 0;
    assign full         = (cnt == 5'd16);
    assign empty        = (cnt == 5'd0);
    assign almost_full  = (cnt >= 5'd13);
    assign almost_empty = (cnt <= 5'd2);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0; rd_ptr <= 0; cnt <= 0; dout <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 4'd1;
            end
            if (rd_en && !empty) begin
                dout <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 4'd1;
            end
            case ({wr_en && !full, rd_en && !empty})
                2'b10: cnt <= cnt + 5'd1;
                2'b01: cnt <= cnt - 5'd1;
                default: cnt <= cnt;
            endcase
        end
    end
endmodule
