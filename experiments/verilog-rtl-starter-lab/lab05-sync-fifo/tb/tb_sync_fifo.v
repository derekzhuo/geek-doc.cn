`timescale 1ns/1ps

module tb_sync_fifo;
  integer errors = 0;
`include "tb_tasks.vh"

  reg        clk = 0;
  reg        rst_n;
  reg        wr_en;
  reg        rd_en;
  reg  [7:0] wr_data;
  wire [7:0] rd_data;
  wire       full;
  wire       empty;
  wire [4:0] count;

  always #5 clk = ~clk;

  // DUT under full test: 16-deep FIFO.
  sync_fifo #(.WIDTH(8), .DEPTH(16)) dut (
    .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
    .wr_data(wr_data), .rd_data(rd_data),
    .full(full), .empty(empty), .count(count)
  );

  // Second instance with different parameters: proves parameterization.
  reg        w4, r4;
  reg  [7:0] d4;
  wire [7:0] q4;
  wire       f4, e4;
  wire [2:0] c4;
  sync_fifo #(.WIDTH(8), .DEPTH(4)) fifo4 (
    .clk(clk), .rst_n(rst_n), .wr_en(w4), .rd_en(r4),
    .wr_data(d4), .rd_data(q4),
    .full(f4), .empty(e4), .count(c4)
  );

  integer i;
  reg [7:0] got;

  initial begin
    $dumpfile("lab05-sync-fifo/sim_build/lab05.vcd");
    $dumpvars(0, tb_sync_fifo);

    rst_n   = 0;
    wr_en   = 0;
    rd_en   = 0;
    wr_data = 8'd0;
    w4 = 0; r4 = 0; d4 = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    check_input(empty == 1'b1, "reset makes 16-deep FIFO empty");
    check_input(full == 1'b0, "reset leaves FIFO not full");
    check_input(count == 5'd0, "count starts at zero");

    // Fill: 16 back-to-back writes, data 0..15. NBA drives at the edge
    // so the DUT samples stable values at the following posedge.
    for (i = 0; i < 16; i = i + 1) begin
      @(posedge clk) begin
        wr_en   <= 1;
        wr_data <= i[7:0];
      end
    end
    @(posedge clk) wr_en <= 0;
    #1;
    check_input(full == 1'b1, "FIFO reports full after 16 writes");
    check_input(count == 5'd16, "count equals depth when full");

    // A write while full must be ignored, count must not move.
    @(posedge clk) begin
      wr_en   <= 1;
      wr_data <= 8'hEE;
    end
    @(posedge clk) wr_en <= 0;
    #1;
    check_input(count == 5'd16, "write while full is ignored");

    // Drain: rd_data is combinational (current rd_ptr entry), so sample
    // before the advancing clock edge.
    for (i = 0; i < 16; i = i + 1) begin
      rd_en = 1;
      #1 got = rd_data;
      check_input(got == i[7:0], "read data follows FIFO write order");
      @(posedge clk) ;
    end
    @(posedge clk) rd_en = 0;
    #1;
    check_input(empty == 1'b1, "FIFO empty after draining all entries");
    check_input(count == 5'd0, "count back to zero after drain");

    // A read while empty must be ignored.
    @(posedge clk) rd_en <= 1;
    @(posedge clk) rd_en <= 0;
    #1;
    check_input(empty == 1'b1 && count == 5'd0, "read while empty is ignored");

    // --- Parameterized 4-deep instance ---
    check_input(e4 == 1'b1, "4-deep instance starts empty");
    for (i = 0; i < 4; i = i + 1) begin
      @(posedge clk) begin
        w4 <= 1;
        d4 <= 8'h10 + i[7:0];
      end
    end
    @(posedge clk) w4 <= 0;
    #1;
    check_input(f4 == 1'b1 && c4 == 3'd4, "4-deep instance fills at 4 entries");
    r4 = 1;
    #1 check_input(q4 == 8'h10, "4-deep instance reads first entry first");
    @(posedge clk) ;
    #1 check_input(q4 == 8'h11, "4-deep instance reads second entry next");
    @(posedge clk) r4 = 0;

    finish_summary(errors);
  end
endmodule
