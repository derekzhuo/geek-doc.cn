`timescale 1ns/1ps
// async_fifo 测试平台：
// 阶段1 写满判满；阶段2 读空判空；阶段3 双时钟并发随机读写 + 数据一致性校验
module tb_async_fifo;

    localparam WIDTH = 8;
    localparam DEPTH = 16;

    reg wr_clk = 0, rd_clk = 0;
    reg wr_rst_n = 0, rd_rst_n = 0;
    reg wr_en = 0, rd_en = 0;
    reg  [WIDTH-1:0] wr_data = 0;
    wire [WIDTH-1:0] rd_data;
    wire full, empty;

    async_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n),
        .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    // 写时钟 100 MHz（周期 10ns），读时钟约 71.4 MHz（周期 14ns），不同频率
    always #5  wr_clk = ~wr_clk;
    always #7  rd_clk = ~rd_clk;

    integer errors = 0;
    integer i;

    // 记分板：期望数据队列
    reg [WIDTH-1:0] expq [0:255];
    integer wh = 0, rh = 0;

    task check(input cond, input [511:0] msg);
        if (!cond) begin
            errors = errors + 1;
            $display("[FAIL] %0s at %0t", msg, $time);
        end else begin
            $display("[OK]   %0s at %0t", msg, $time);
        end
    endtask

    initial begin
        // 双域复位
        wr_rst_n = 0; rd_rst_n = 0;
        #50;
        wr_rst_n = 1; rd_rst_n = 1;
        #20;

        // ---- 阶段 1：写满判满 ----
        $display("== Phase 1: fill until full ==");
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge wr_clk);
            wr_en = 1; wr_data = i;
        end
        @(negedge wr_clk);
        wr_en = 0;
        // full 是写域寄存量，最后一次写入后再等一拍生效
        @(posedge wr_clk); #1;
        check(full === 1'b1, "full asserted when FIFO filled");
        check(empty === 1'b0, "empty not asserted when full");

        // ---- 阶段 2：读空判空 ----
        $display("== Phase 2: drain until empty ==");
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge rd_clk);
            rd_en = 1;
        end
        @(negedge rd_clk);
        rd_en = 0;
        // empty 是读域寄存量，最后一次读出后再等一拍生效
        @(posedge rd_clk); #1;
        check(empty === 1'b1, "empty asserted when FIFO drained");
        // full 在写域判定，读指针经两级同步器回传，需等若干写时钟
        repeat (4) @(posedge wr_clk);
        check(full === 1'b0, "full deasserted after drain (write domain synced)");

        // 核对读出的数据顺序（在阶段2中由下方读监视进程完成）

        // ---- 阶段 3：双时钟并发随机读写 ----
        $display("== Phase 3: concurrent random rd/wr, wr=100MHz rd=71.4MHz ==");
        fork
            begin : writer
                repeat (120) begin
                    @(negedge wr_clk);
                    wr_en = ($random % 3) != 0;   // 2/3 概率写
                    if (wr_en) wr_data = $random;
                end
                wr_en = 0;
            end
            begin : reader
                repeat (120) begin
                    @(negedge rd_clk);
                    rd_en = ($random % 3) != 0;   // 2/3 概率读
                end
                rd_en = 0;
            end
        join

        // 排空剩余数据
        repeat (DEPTH + 4) begin
            @(negedge rd_clk);
            rd_en = 1;
        end
        rd_en = 0;

        repeat (4) @(posedge rd_clk);
        check(empty === 1'b1, "empty asserted at end of phase 3");
        check(wh == rh, "scoreboard fully drained: write count == read count");

        if (errors == 0)
            $display("== TEST PASSED: 0 errors ==");
        else
            $display("== TEST FAILED: %0d errors ==", errors);
        $finish;
    end

    // 写侧记分：实际写入成功时入队期望值
    always @(posedge wr_clk) begin
        if (wr_rst_n && wr_en && !full) begin
            expq[wh] = wr_data; wh = wh + 1;
        end
    end

    // 读侧记分：实际读出成功时对拍
    always @(posedge rd_clk) begin
        if (rd_rst_n && rd_en && !empty) begin
            if (rd_data !== expq[rh]) begin
                errors = errors + 1;
                $display("[FAIL] data mismatch: got %02x expect %02x at %0t", rd_data, expq[rh], $time);
            end
            rh = rh + 1;
        end
    end

endmodule
