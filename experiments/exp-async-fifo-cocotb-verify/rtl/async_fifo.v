`timescale 1ns/1ps
// async_fifo.v — standard dual-clock asynchronous FIFO (Gray pointer + dual synchronizers)
// Lab target: cocotb random read/write regression, full/empty boundary coverage.
// Educational, synthesizable subset (no vendor cells).
`default_nettype none
module async_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,           // MUST be power of two
    parameter AW    = $clog2(DEPTH)
)(
    input  wire             wclk, wrst_n, wr_en,
    input  wire [WIDTH-1:0] wdata,
    output wire             full,
    input  wire             rclk, rrst_n, rd_en,
    output wire [WIDTH-1:0] rdata,
    output wire             empty
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0] wbin, wgray;
    reg [AW:0] rbin, rgray;
    reg [AW:0] wq1_rgray, wq2_rgray;
    reg [AW:0] rq1_wgray, rq2_wgray;

    // -------- write side --------
    wire [AW:0] wbin_next  = wbin + (wr_en & ~full);
    wire [AW:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) begin wbin <= 0; wgray <= 0; end
        else            begin wbin <= wbin_next; wgray <= wgray_next; end

    always @(posedge wclk)
        if (wr_en && !full) mem[wbin[AW-1:0]] <= wdata;

    // synchronized read pointer into write domain
    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) begin wq1_rgray <= 0; wq2_rgray <= 0; end
        else          begin wq1_rgray <= rgray; wq2_rgray <= wq1_rgray; end

    // full 必须寄存（Cummings 标准形）：组合输出会与 wbin_next 形成
    // full -> wbin_next -> wgray_next -> full 零延迟振荡环，仿真器 delta 风暴卡死
    reg full_r;
    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) full_r <= 1'b0;
        else         full_r <= (wgray_next == {~wq2_rgray[AW:AW-1], wq2_rgray[AW-2:0]});
    assign full = full_r;

    // -------- read side --------
    wire [AW:0] rbin_next  = rbin + (rd_en & ~empty);
    wire [AW:0] rgray_next = (rbin_next >> 1) ^ rbin_next;
    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) begin rbin <= 0; rgray <= 0; end
        else          begin rbin <= rbin_next; rgray <= rgray_next; end

    assign rdata = mem[rbin[AW-1:0]];

    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) begin rq1_wgray <= 0; rq2_wgray <= 0; end
        else          begin rq1_wgray <= wgray; rq2_wgray <= rq1_wgray; end

    // empty 同理寄存；复位后为 1（空）
    reg empty_r;
    always @(posedge rclk or negedge rrst_n)
        if (!rrst_n) empty_r <= 1'b1;
        else         empty_r <= (rgray_next == rq2_wgray);
    assign empty = empty_r;
endmodule
`default_nettype wire
