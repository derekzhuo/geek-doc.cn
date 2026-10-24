// Self-checking regression TB for sync_fifo:
//   phase 1: fill to full, drain to empty (order + flag checks)
//   phase 2: random read/write stress with queue scoreboard
//   phase 3: wrap-around boundary (pointers wrap with data intact)
`timescale 1ns/1ps
module tb_sync_fifo;
    parameter DW = 8;
    parameter AW = 3;
    localparam DEPTH = (1 << AW);

    reg clk = 0, rst_n = 0;
    reg wr_en = 0, rd_en = 0;
    reg [DW-1:0] wr_data = 0;
    wire [DW-1:0] rd_data;
    wire full, empty, almost_full, almost_empty;

    sync_fifo #(.DW(DW), .AW(AW)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .full(full), .almost_full(almost_full),
        .rd_en(rd_en), .rd_data(rd_data), .empty(empty), .almost_empty(almost_empty)
    );

    always #5 clk = ~clk;

    // scoreboard on negedge (+#1 to settle NBA drives): predicts what the DUT
    // will do at the next posedge using the same flags the DUT will see.
    integer errors = 0;
    integer i;
    reg [DW-1:0] model [0:1023];
    integer m_wr = 0, m_rd = 0, m_cmp = 0;
    integer pending_read = 0;

    always @(negedge clk) begin
        #1;
        if (rst_n) begin
            // check data popped at the posedge half a cycle ago
            if (pending_read) begin
                if (rd_data !== model[m_cmp]) begin
                    errors = errors + 1;
                    $display("[%0t] MISMATCH got=%0d expect=%0d (m_cmp=%0d)",
                             $time, rd_data, model[m_cmp], m_cmp);
                end
                m_cmp = m_cmp + 1;
            end
            if (wr_en && !full) begin
                model[m_wr] = wr_data;
                m_wr = m_wr + 1;
            end
            pending_read = (rd_en && !empty);
            if (pending_read) m_rd = m_rd + 1;
        end else begin
            pending_read = 0;
        end
    end

    task check_flag;
        input cond;
        input [127:0] name;
        begin
            if (!cond) begin
                errors = errors + 1;
                $display("[%0t] FLAG ERROR: %0s wrong", $time, name);
            end
        end
    endtask

    initial begin
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);
        repeat (4) @(posedge clk);
        rst_n <= 1;
        @(negedge clk);

        // ---- phase 1: fill to full ----
        $display("== phase 1: fill to full ==");
        for (i = 0; i < DEPTH; i = i + 1) begin
            wr_en <= 1; wr_data <= i;
            @(negedge clk);
        end
        wr_en <= 0;
        @(posedge clk); #1;
        check_flag(full, "full");
        check_flag(almost_full, "almost_full");
        // overflow attempt must be ignored
        wr_en <= 1; wr_data <= 8'hEE;
        @(negedge clk);
        wr_en <= 0;
        if (m_wr != DEPTH) begin
            errors = errors + 1;
            $display("overflow attempt leaked: m_wr=%0d", m_wr);
        end

        // ---- phase 2: drain to empty ----
        $display("== phase 2: drain to empty ==");
        rd_en <= 1;
        repeat (DEPTH + 2) @(negedge clk);
        rd_en <= 0;
        @(posedge clk); #1;
        check_flag(empty, "empty");
        check_flag(almost_empty, "almost_empty");
        if (m_rd != DEPTH) begin
            errors = errors + 1;
            $display("drain count wrong: m_rd=%0d expect %0d", m_rd, DEPTH);
        end

        // ---- phase 3: random stress (covers wrap-around many times) ----
        $display("== phase 3: random stress ==");
        for (i = 0; i < 400; i = i + 1) begin
            wr_en <= ($random % 3 != 0);
            rd_en <= ($random % 3 == 0);
            wr_data <= $random;
            @(negedge clk);
        end
        wr_en <= 0; rd_en <= 1;
        repeat (DEPTH + 4) @(negedge clk);
        rd_en <= 0;

        @(posedge clk); #1;
        if (m_wr != m_rd) begin
            errors = errors + 1;
            $display("final count mismatch: m_wr=%0d m_rd=%0d", m_wr, m_rd);
        end
        $display("total transfers=%0d errors=%0d", m_wr, errors);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $finish;
    end
endmodule
