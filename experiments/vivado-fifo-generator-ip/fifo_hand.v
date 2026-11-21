`timescale 1ns/1ps
module fifo_hand (
    input wire clk,
    input wire srst,
    input wire [7:0] din,
    input wire wr_en,
    input wire rd_en,
    output reg [7:0] dout,
    output wire full,
    output wire almost_full,
    output wire empty,
    output wire almost_empty
);
    (* ram_style = "block" *) reg [7:0] mem [0:15];
    reg [3:0] wptr = 0;
    reg [3:0] rptr = 0;
    reg [4:0] count = 0;
    wire write_ok = wr_en && !full;
    wire read_ok = rd_en && !empty;

    assign full = count == 16;
    assign almost_full = count >= 15;
    assign empty = count == 0;
    assign almost_empty = count <= 1;

    always @(posedge clk) begin
        if (srst) begin
            wptr <= 0;
            rptr <= 0;
            count <= 0;
            dout <= 0;
        end else begin
            if (write_ok) begin
                mem[wptr] <= din;
                wptr <= wptr + 1'b1;
            end
            if (read_ok) begin
                dout <= mem[rptr];
                rptr <= rptr + 1'b1;
            end
            case ({write_ok, read_ok})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end
endmodule
