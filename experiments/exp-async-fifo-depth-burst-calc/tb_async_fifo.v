// Testbench: burst-write 16 items into async FIFO while reading continuously.
// wr_clk 10 ns, rd_clk 20 ns (write rate = 2x read rate).
// AW is overridden from the command line (-Ptb_async_fifo.AW=...) so the same
// TB exercises a deep-enough FIFO and a too-shallow FIFO.
`timescale 1ns/1ps
module tb_async_fifo;
    parameter AW = 4;               // depth = 2**AW, overridden by run.sh
    parameter DW = 8;
    parameter BURST = 16;

    reg wr_clk = 0, rd_clk = 0;
    reg wr_rst_n = 0, rd_rst_n = 0;
    reg wr_en = 0;
    reg [DW-1:0] wr_data = 0;
    wire full;
    reg rd_en = 0;
    wire [DW-1:0] rd_data;
    wire empty;

    async_fifo #(.DW(DW), .AW(AW)) dut (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n), .wr_en(wr_en),
        .wr_data(wr_data), .full(full),
        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n), .rd_en(rd_en),
        .rd_data(rd_data), .empty(empty)
    );

    always #5  wr_clk = ~wr_clk;    // 100 MHz
    always #10 rd_clk = ~rd_clk;    // 50 MHz

    integer wr_attempted = 0;
    integer dropped = 0;
    integer rd_count = 0;
    integer mismatch = 0;
    reg [DW-1:0] model [0:255];
    integer wr_idx = 0;
    integer rd_idx = 0;

    // scoreboard: sample on posedge, after NBA updates settle (#1)
    always @(posedge wr_clk) begin
        #1;
        if (wr_rst_n && wr_en) begin
            wr_attempted = wr_attempted + 1;
            if (full) begin
                dropped = dropped + 1;
                $display("[%0t] OVERFLOW drop data=%0d (full=1)", $time, wr_data);
            end else begin
                model[wr_idx] = wr_data;
                wr_idx = wr_idx + 1;
            end
        end
    end

    // read-side scoreboard: detect read-pointer increments (race-free vs empty flag)
    integer prev_rptr = -1;
    always @(posedge rd_clk) begin
        #1;
        if (rd_rst_n) begin
            if (prev_rptr >= 0 && dut.rptr_bin !== prev_rptr) begin
                rd_count = rd_count + 1;
                if (rd_data !== model[rd_idx]) begin
                    mismatch = mismatch + 1;
                    $display("[%0t] MISMATCH got=%0d expect=%0d", $time, rd_data, model[rd_idx]);
                end
                rd_idx = rd_idx + 1;
            end
            prev_rptr = dut.rptr_bin;
        end
    end

    integer i;
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
        repeat (4) @(posedge wr_clk);
        wr_rst_n <= 1; rd_rst_n <= 1;
        @(negedge wr_clk);

        // burst: try to push BURST items back-to-back
        for (i = 0; i < BURST; i = i + 1) begin
            wr_en   <= 1;
            wr_data <= i + 1;
            @(negedge wr_clk);
        end
        wr_en <= 0;

        // drain (generous window to cover sync latency)
        repeat (200) @(posedge rd_clk);

        $display("---- RESULTS (AW=%0d, DEPTH=%0d, BURST=%0d) ----", AW, (1<<AW), BURST);
        $display("WR_ATTEMPTED=%0d DROPPED=%0d RD_COUNT=%0d MISMATCH=%0d",
                 wr_attempted, dropped, rd_count, mismatch);
        if (dropped == 0 && mismatch == 0 && rd_count == BURST)
            $display("GROUP_RESULT: PASS");
        else
            $display("GROUP_RESULT: FAIL");
        $finish;
    end

    // continuous read: pop whenever not empty
    always @(negedge rd_clk) begin
        if (rd_rst_n && !empty) rd_en <= 1;
        else                    rd_en <= 0;
    end
endmodule
