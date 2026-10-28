// 同步 FIFO 两种实现的自校验测试平台
// 阶段1 写满判满 -> 阶段2 读空判空 -> 阶段3 满时并发读写保持满 -> 阶段4 随机压力记分板对拍
`timescale 1ns/1ps
module tb_sync_fifo;

    localparam WIDTH = 8;
    localparam DEPTH = 16;
    localparam AW    = 4;

    reg clk = 0;
    reg rst_n = 0;
    reg wr_en = 0;
    reg [WIDTH-1:0] wr_data = 0;
    reg rd_en = 0;
    wire full_c, empty_c, full_p, empty_p;
    wire [WIDTH-1:0] rd_data_c, rd_data_p;
    wire [AW:0] count_c;

    integer errors = 0;
    integer transfers = 0;

    // DUT1：计数器法
    sync_fifo_count #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut_count (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .full(full_c),
        .rd_en(rd_en), .rd_data(rd_data_c), .empty(empty_c),
        .count(count_c)
    );

    // DUT2：指针法（同一组激励，输出应完全一致）
    sync_fifo_ptr #(.WIDTH(WIDTH), .AW(AW)) dut_ptr (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .full(full_p),
        .rd_en(rd_en), .rd_data(rd_data_p), .empty(empty_p)
    );

    always #5 clk = ~clk;

    // 记分板：环形数组模拟期望队列
    reg [WIDTH-1:0] sb [0:65535];   // 足够装下 2000 拍全部写入
    integer sb_head = 0;
    integer sb_tail = 0;

    task sb_push(input [WIDTH-1:0] d);
        begin sb[sb_tail] = d; sb_tail = sb_tail + 1; end
    endtask

    task sb_pop_check(input [WIDTH-1:0] got, input [127:0] who);
        begin
            if (got !== sb[sb_head]) begin
                errors = errors + 1;
                $display("[ERROR] %0s mismatch: got %02x expect %02x", who, got, sb[sb_head]);
            end
            sb_head = sb_head + 1;
            transfers = transfers + 1;
        end
    endtask

    // 记分板与 DUT 接受条件完全一致：未满可写，满但有读也可写；非空可读
    wire sb_wr_acc = rst_n & wr_en & (~full_c | rd_en);
    wire sb_rd_acc = rst_n & rd_en & ~empty_c;

    // 单个 always 块内先读旧队首、再推入新数据，避免多块并发竞争
    always @(posedge clk) begin
        if (sb_rd_acc) begin
            if (rd_data_c !== sb[sb_head]) begin
                errors = errors + 1;
                $display("[ERROR] count mismatch: got %02x expect %02x", rd_data_c, sb[sb_head]);
            end
            if (rd_data_p !== sb[sb_head]) begin
                errors = errors + 1;
                $display("[ERROR] ptr mismatch: got %02x expect %02x", rd_data_p, sb[sb_head]);
            end
            sb_head = sb_head + 1;
            transfers = transfers + 1;
        end
        if (sb_wr_acc)
            sb_push(wr_data);
    end
    // 标志一致性：两个实现任何时刻 full/empty 必须相同
    always @(posedge clk) begin
        if (rst_n && (full_c !== full_p || empty_c !== empty_p)) begin
            errors = errors + 1;
            $display("[ERROR] flag mismatch: count full=%b empty=%b, ptr full=%b empty=%b",
                     full_c, empty_c, full_p, empty_p);
        end
    end

    task do_write(input [WIDTH-1:0] d);
        begin
            @(negedge clk); wr_en = 1; wr_data = d;
            @(negedge clk); wr_en = 0;
        end
    endtask

    task do_read;
        begin
            @(negedge clk); rd_en = 1;
            @(negedge clk); rd_en = 0;
        end
    endtask

    integer i;
    reg [WIDTH-1:0] r;

    initial begin
        // 复位
        repeat (4) @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        // ---- 阶段 1：连续写满，满标志必须恰好在 DEPTH 次写入后拉高 ----
        $display("[PHASE1] fill until full");
        for (i = 0; i < DEPTH; i = i + 1)
            do_write(i[WIDTH-1:0]);
        if (!full_c || !full_p) begin
            errors = errors + 1;
            $display("[ERROR] full not asserted after %0d writes", DEPTH);
        end else
            $display("[OK] full asserted after %0d writes (count=%0d)", DEPTH, count_c);
        // 满后再写一拍，应被拒绝（计数不变）
        do_write(8'hff);
        if (count_c !== DEPTH[AW:0]) begin
            errors = errors + 1;
            $display("[ERROR] write accepted while full");
        end else
            $display("[OK] write while full rejected");

        // ---- 阶段 2：连续读空，空标志恰好拉高 ----
        $display("[PHASE2] drain until empty");
        for (i = 0; i < DEPTH; i = i + 1)
            do_read;
        if (!empty_c || !empty_p) begin
            errors = errors + 1;
            $display("[ERROR] empty not asserted after %0d reads", DEPTH);
        end else
            $display("[OK] empty asserted after %0d reads", DEPTH);
        // 空后再读一拍，应被拒绝
        do_read;
        if (count_c !== 0) begin
            errors = errors + 1;
            $display("[ERROR] read accepted while empty");
        end else
            $display("[OK] read while empty rejected");

        // ---- 阶段 3：填满后并发读写，满必须保持、计数恒为 DEPTH ----
        $display("[PHASE3] simultaneous rd/wr while full");
        for (i = 0; i < DEPTH; i = i + 1)
            do_write(i[WIDTH-1:0] + 8'h40);
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk); wr_en = 1; rd_en = 1; wr_data = 8'h80 + i[WIDTH-1:0];
            @(negedge clk); wr_en = 0; rd_en = 0;
            if (!full_c || !full_p) begin
                errors = errors + 1;
                $display("[ERROR] full deasserted during simultaneous rd/wr");
            end
        end
        if (count_c !== DEPTH[AW:0]) begin
            errors = errors + 1;
            $display("[ERROR] count drifted: %0d", count_c);
        end else
            $display("[OK] full held during 8 simultaneous rd/wr cycles, count=%0d", count_c);
        // 排空这段数据，为阶段 4 清零
        for (i = 0; i < DEPTH; i = i + 1)
            do_read;

        // ---- 阶段 4：随机压力 2000 拍，记分板逐拍对拍 ----
        $display("[PHASE4] random stress 2000 cycles");
        for (i = 0; i < 2000; i = i + 1) begin
            @(negedge clk);
            r = $random;
            wr_en = ($random % 3 != 0);   // 约 2/3 概率写
            rd_en = ($random % 3 != 0);   // 约 2/3 概率读
            wr_data = r;
        end
        @(negedge clk); wr_en = 0; rd_en = 0;

        if (errors == 0)
            $display("TEST PASSED: 0 errors, %0d transfers", transfers);
        else
            $display("TEST FAILED: %0d errors, %0d transfers", errors, transfers);
        $finish;
    end

endmodule
