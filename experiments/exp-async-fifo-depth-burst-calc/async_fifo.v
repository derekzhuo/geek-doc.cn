// Parameterized asynchronous FIFO with Gray-code pointers.
// Depth = 1 << AW. Standard two-flop pointer synchronization.
module async_fifo #(
    parameter DW = 8,   // data width
    parameter AW = 4    // address width, depth = 2**AW
)(
    input  wire           wr_clk,
    input  wire           wr_rst_n,
    input  wire           wr_en,
    input  wire [DW-1:0]  wr_data,
    output wire           full,

    input  wire           rd_clk,
    input  wire           rd_rst_n,
    input  wire           rd_en,
    output reg  [DW-1:0]  rd_data,
    output wire           empty
);
    localparam DEPTH = (1 << AW);

    reg [DW-1:0] mem [0:DEPTH-1];

    reg [AW:0] wptr_bin, rptr_bin;      // one extra wrap bit
    reg [AW:0] wptr_gray, rptr_gray;
    reg [AW:0] rq1_wgray, rq2_wgray;    // write ptr synced into read domain
    reg [AW:0] wq1_rgray, wq2_rgray;    // read ptr synced into write domain

    wire [AW:0] wbin_next  = wptr_bin + ((wr_en && !full) ? 1'b1 : 1'b0);
    wire [AW:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
    wire [AW:0] rbin_next  = rptr_bin + ((rd_en && !empty) ? 1'b1 : 1'b0);
    wire [AW:0] rgray_next = (rbin_next >> 1) ^ rbin_next;

    // full/empty are registered (avoids combinational loop flag -> next ptr -> flag)
    reg full_r, empty_r;
    assign full  = full_r;
    assign empty = empty_r;

    // write domain
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wptr_bin  <= 0;
            wptr_gray <= 0;
            wq1_rgray <= 0;
            wq2_rgray <= 0;
            full_r    <= 0;
        end else begin
            wq1_rgray <= rptr_gray;
            wq2_rgray <= wq1_rgray;
            full_r    <= (wgray_next == {~wq2_rgray[AW:AW-1], wq2_rgray[AW-2:0]});
            if (wr_en && !full) begin
                mem[wptr_bin[AW-1:0]] <= wr_data;
                wptr_bin  <= wbin_next;
                wptr_gray <= wgray_next;
            end
        end
    end

    // read domain
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rptr_bin  <= 0;
            rptr_gray <= 0;
            rq1_wgray <= 0;
            rq2_wgray <= 0;
            rd_data   <= 0;
            empty_r   <= 1'b1;
        end else begin
            rq1_wgray <= wptr_gray;
            rq2_wgray <= rq1_wgray;
            empty_r   <= (rgray_next == rq2_wgray);
            if (rd_en && !empty) begin
                rd_data   <= mem[rptr_bin[AW-1:0]];
                rptr_bin  <= rbin_next;
                rptr_gray <= rgray_next;
            end
        end
    end
endmodule
