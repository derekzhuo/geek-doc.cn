// Parameterized synchronous FIFO with full/empty/almost flags.
module sync_fifo #(
    parameter DW = 8,
    parameter AW = 3,                 // depth = 2**AW
    parameter ALMOST = 2              // almost threshold (entries)
)(
    input  wire           clk,
    input  wire           rst_n,
    input  wire           wr_en,
    input  wire [DW-1:0]  wr_data,
    output wire           full,
    output wire           almost_full,
    input  wire           rd_en,
    output reg  [DW-1:0]  rd_data,
    output wire           empty,
    output wire           almost_empty
);
    localparam DEPTH = (1 << AW);

    reg [DW-1:0] mem [0:DEPTH-1];
    reg [AW:0] wptr, rptr;            // extra wrap bit

    wire [AW:0] used = wptr - rptr;
    assign full         = (used == DEPTH);
    assign empty        = (used == 0);
    assign almost_full  = (used >= DEPTH - ALMOST);
    assign almost_empty = (used <= ALMOST);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0;
        end else if (wr_en && !full) begin
            mem[wptr[AW-1:0]] <= wr_data;
            wptr <= wptr + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr    <= 0;
            rd_data <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= mem[rptr[AW-1:0]];
            rptr    <= rptr + 1'b1;
        end
    end
endmodule
